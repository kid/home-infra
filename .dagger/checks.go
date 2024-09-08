package main

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"go.opentelemetry.io/otel/codes"
	"golang.org/x/sync/errgroup"
)

func (m *HomeInfra) Check(
	ctx context.Context,
	// +optional
	// +default=[""]
	targets []string,
) error {
	var routes checkRouter
	tfChecks, err := m.terraformChecks(ctx)
	if err != nil {
		return err
	}
	routes.Add(tfChecks...)

	eg := errgroup.Group{}
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
			if m.IsCi {
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
	var routes checkRouter
	tfChecks, err := m.terraformChecks(ctx)
	if err != nil {
		return
	}
	routes.Add(tfChecks...)

	for _, check := range routes.Get(targets...) {
		checks = append(checks, check.Name)
	}

	return
}

type Check struct {
	Name  string
	Check func(context.Context) error
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

type checkRouter struct {
	check    Check
	children map[string]*checkRouter
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
