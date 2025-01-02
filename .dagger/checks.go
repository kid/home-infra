package main

import (
	"context"
	"errors"
	"fmt"
	"path"
	"path/filepath"
	"strings"

	"go.opentelemetry.io/otel/codes"
	"golang.org/x/sync/errgroup"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

func buildRoutes(ctx context.Context, m *HomeInfra) (*checkRouter, error) {
	router := &checkRouter{}
	router, err := buildCheckRouter(
		ctx,
		m.Kube(),
	)
	if err != nil {
		return nil, err
	}

	ctrs := dag.Containers()
	targets, err := ctrs.Targets(ctx)
	if err != nil {
		return nil, err
	}
	platforms, err := ctrs.Platforms(ctx)
	if err != nil {
		return nil, err
	}
	for _, target := range targets {
		router.Add(Check{
			Name: path.Join(target, "lint"),
			Check: func(ctx context.Context) error {
				return ctrs.Lint(ctx, target)
			},
		})
		for _, platform := range platforms {
			router.Add(Check{
				Name: path.Join(target, "build", string(platform)),
				Check: func(ctx context.Context) error {
					return ctrs.Build(ctx, target, platform)
				},
			})
		}
	}

	tf := dag.Terraform(dagger.TerraformOpts{
		Token:       m.TfToken,
		SopsAgeKeys: m.SopsAgeKeys,
		IsCi:        m.IsCi,
	})

	router.Add(Check{Name: "terraform/fmt", Check: tf.Fmt})
	router.Add(Check{Name: "terraform/lint", Check: tf.Lint})

	stacks, err := tf.Targets(ctx)
	if err != nil {
		return nil, err
	}
	for _, stack := range stacks {
		dir, err := filepath.Rel("terraform", stack)
		if err != nil {
			return nil, err
		}
		router.Add(Check{
			Name: path.Join(dir, "fmt"),
			Check: func(ctx context.Context) error {
				return tf.Validate(ctx, stack)
			},
		})
	}

	return router, err
}

func (m *HomeInfra) Check(
	ctx context.Context,
	// +optional
	// +default=[""]
	targets []string,
) error {
	routes, err := buildRoutes(ctx, m)
	if err != nil {
		return err
	}

	eg, ctx := errgroup.WithContext(ctx)
	for _, check := range routes.Get(targets...) {
		ctx, span := Tracer().Start(ctx, check.Name)
		eg.Go(func() (rerr error) {
			defer func() {
				if rerr != nil {
					span.SetStatus(codes.Error, rerr.Error())
				}
				span.End()
			}()

			rerr = check.Check(ctx)
			if m.IsCi && m.GhPr > 0 {
				gh := m.Github(ctx, "kid", "home-infra")
				if rerr != nil {
					checkErr := &CheckError{}
					if errors.As(rerr, &checkErr) {
						if checkErr.Markdown != "" {
							gh.CreateOrUpdateComment(ctx, m.GhPr, checkErr.Markdown, check.Name)
						}
					}
				} else {
					gh.DeleteComment(ctx, m.GhPr, check.Name)
				}
			}

			return rerr
		})
	}

	return eg.Wait()
}

func (m *HomeInfra) CheckList(
	ctx context.Context,
	// +optional
	// +default=[""]
	targets []string,
) (checks []string, err error) {
	routes, err := buildRoutes(ctx, m)
	if err != nil {
		return
	}

	for _, check := range routes.Get(targets...) {
		checks = append(checks, check.Name)
	}

	return
}

type CheckError struct {
	original error
	Markdown string
}

func (e *CheckError) Error() string {
	return fmt.Sprintf("check failed: %v", e.original)
}

func (e *CheckError) Message() string {
	// if e.Markdown != "" {
	// 	return e.Markdown
	// }
	return e.original.Error()
}

func (e *CheckError) Unwrap() error {
	return e.original
}

type Check struct {
	Name  string
	Check func(context.Context) error
}

type checkRouter struct {
	check    Check
	children map[string]*checkRouter
}

type checkBuilder interface {
	buildChecks(context.Context) ([]Check, error)
}

func buildCheckRouter(ctx context.Context, builders ...checkBuilder) (*checkRouter, error) {
	router := &checkRouter{}
	for _, builder := range builders {
		checks, err := builder.buildChecks(ctx)
		if err != nil {
			return nil, err
		}
		router.Add(checks...)
	}
	return router, nil
}

func (r *checkRouter) Add(checks ...Check) {
	for _, check := range checks {
		r.add(check.Name, check)
	}
}

func (r *checkRouter) Get(targets ...string) []Check {
	var checks []Check
	for _, target := range targets {
		checks = append(checks, r.get(target).all()...)
	}
	return checks
}

func (r *checkRouter) add(target string, check Check) {
	if target == "" {
		r.check = check
		return
	}

	target, rest, _ := strings.Cut(target, "/")
	if r.children == nil {
		r.children = make(map[string]*checkRouter)
	}
	if _, ok := r.children[target]; !ok {
		r.children[target] = &checkRouter{}
	}
	r.children[target].add(rest, check)
}

func (r *checkRouter) get(target string) *checkRouter {
	if r == nil {
		return nil
	}
	if target == "" {
		return r
	}

	target, rest, _ := strings.Cut(target, "/")
	if r.children == nil {
		return nil
	}
	if _, ok := r.children[target]; !ok {
		return nil
	}
	return r.children[target].get(rest)
}

func (r *checkRouter) all() []Check {
	if r == nil {
		return nil
	}
	var checks []Check
	if r.check.Check != nil {
		checks = append(checks, r.check)
	}
	for _, child := range r.children {
		checks = append(checks, child.all()...)
	}
	return checks
}
