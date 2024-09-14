package main

import (
	"bytes"
	"context"
	"embed"
	"encoding/json"
	"errors"
	"path/filepath"
	"text/template"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

const (
	TF_BINARY = "tofu"
)

type Terraform struct {
	HomeInfra *HomeInfra        // +private
	Ctr       *dagger.Container // +private
	Token     *dagger.Secret    // +private
}

func (m *HomeInfra) terraformChecks(ctx context.Context) ([]Check, error) {
	tf := m.Terraform(ctx, nil)
	name := "terraform"
	checks := []Check{
		{
			Name:  name + "/fmt",
			Check: tf.Fmt,
		},
		{
			Name:  name + "/lint",
			Check: tf.Lint,
		},
	}

	stacks, err := Containing(ctx, m.Source, ".terraform.lock.hcl")
	if err != nil {
		return nil, err
	}
	for _, stack := range stacks {
		dir, err := filepath.Rel("terraform", stack)
		if err != nil {
			return nil, err
		}
		checks = append(checks, Check{
			Name: name + "/validate/" + dir,
			Check: func(ctx context.Context) error {
				return tf.Validate(ctx, stack)
			},
		})
	}

	return checks, nil
}

func (m *HomeInfra) Terraform(
	ctx context.Context,
	// +optional
	token *dagger.Secret,
) *Terraform {
	tf := &Terraform{
		HomeInfra: m,
		// Source:    source,
		Token: token,
	}
	return tf
}

func (m *Terraform) Base(ctx context.Context) (ctr *dagger.Container, err error) {
	if m.Ctr == nil {
		ctr = dag.
			Wolfi().
			Container(dagger.WolfiContainerOpts{
				Packages: []string{
					"opentofu=1.8.2",
					"tflint=0.53.0",
				},
			}).
			WithMountedCache("~/.terraform.d/plugin-cache", dag.CacheVolume("terraform-plugin-cache")).
			WithEnvVariable("TF_IN_AUTOMATION", "true").
			WithDirectory("/src", m.HomeInfra.Source).
			WithWorkdir("/src")

		if m.Token != nil {
			ctr = ctr.WithSecretVariable("TF_TOKEN_app_terraform_io", m.Token)
		}

		if m.HomeInfra.SopsKey != nil {
			ctr = ctr.WithMountedSecret("/root/.config/sops/age/keys.txt", m.HomeInfra.SopsKey)
		}

		ctr, err = ctr.Sync(ctx)
		if err != nil {
			return
		}
		m.Ctr = ctr
	}

	return m.Ctr, err
}

func (m *Terraform) Fmt(ctx context.Context) (err error) {
	ctr, err := m.Base(ctx)
	if err != nil {
		return err
	}

	_, err = ctr.WithExec([]string{TF_BINARY, "fmt", "-recursive", "-diff", "-check"}).Sync(ctx)
	if err != nil {
		if execError, ok := err.(*dagger.ExecError); ok {
			return &CheckError{
				Markdown: "### `terraform fmt`:\n```diff\n" + execError.Stdout + "\n```",
				original: err,
			}
		}
	}

	return
}

func (m *Terraform) FmtFix(ctx context.Context) (dir *dagger.Directory, err error) {
	ctr, err := m.Base(ctx)
	if err != nil {
		return
	}
	ctr, err = ctr.WithExec([]string{TF_BINARY, "fmt", "-recursive", "-diff"}).Sync(ctx)

	if err != nil {
		return
	}

	return ctr.Directory("/src"), err
}

func (m *Terraform) Lint(ctx context.Context) error {
	args := []string{"tflint", "--recursive", "--minimum-failure-severity=warning"}
	if m.HomeInfra.IsCi {
		args = append(args, "--format", "json")
	} else {
		args = append(args, "--color")
	}
	ctr, err := m.Base(ctx)
	if err != nil {
		return err
	}
	_, err = ctr.WithExec(args).Sync(ctx)
	if execError, ok := err.(*dagger.ExecError); ok {
		md, err := m.LintReport(ctx, execError.Stdout)
		if err != nil {
			return errors.Join(err, execError)
		}
		return &CheckError{
			Markdown: md,
			original: execError,
		}
	}

	return err
}

func (m *Terraform) LintFix(ctx context.Context) (*dagger.Directory, error) {
	ctr, err := m.Base(ctx)
	if err != nil {
		return nil, err
	}
	_, err = ctr.WithExec([]string{"tflint", "--color", "--recursive", "--fix", "--force"}).Sync(ctx)
	if err != nil {
		return nil, err
	}

	return ctr.Directory("/src"), err
}

func (m *Terraform) Init(
	ctx context.Context,
	// Directory to initialize
	chdir string,
	// Whether to upgrade modules and providers
	// +default=false
	upgrade bool,
	// Whether to reconfigure the backend
	// +default=false
	reconfigure bool,
) (ctr *dagger.Container, err error) {
	args := []string{
		TF_BINARY,
		"-chdir=" + chdir,
		"init",
	}
	if m.Token == nil {
		args = append(args, "-backend=false")
	}
	if upgrade {
		args = append(args, "-upgrade")
	}
	if reconfigure {
		args = append(args, "-reconfigure")
	}
	ctr, err = m.Base(ctx)
	if err != nil {
		return
	}
	ctr, err = ctr.WithExec(args).Sync(ctx)
	if err != nil {
		return
	}
	return
}

func (m *Terraform) Validate(
	ctx context.Context,
	// Directory to validate
	chdir string,
) (err error) {
	ctr, err := m.Init(ctx, chdir, false, false)
	if err != nil {
		return err
	}

	args := []string{TF_BINARY, "-chdir=" + chdir, "validate"}
	if m.HomeInfra.IsCi {
		args = append(args, "-json")
	}
	ctr, err = ctr.WithExec(args).Sync(ctx)
	if err != nil {
		return
	}

	return err
}

func (m *Terraform) Plan(
	ctx context.Context,
	// Directory to validate
	chdir string,
) (ctr *dagger.Container, err error) {
	ctr, err = m.Init(ctx, chdir, false, false)
	if err != nil {
		return
	}

	args := []string{TF_BINARY, "-chdir=" + chdir, "plan", "-out=plan.tfplan"}
	if m.HomeInfra.IsCi {
		args = append(args, "-json")
	}
	ctr, err = ctr.WithExec(args).Sync(ctx)
	if err != nil {
		return
	}

	return
}

func (m *Terraform) Apply(
	ctx context.Context,
	// Directory to validate
	chdir string,
) (ctr *dagger.Container, err error) {
	ctr, err = m.Plan(ctx, chdir)
	if err != nil {
		return
	}

	args := []string{TF_BINARY, "-chdir=" + chdir, "apply", "plan.tfplan"}
	if m.HomeInfra.IsCi {
		args = append(args, "-json")
	}
	ctr, err = ctr.WithExec(args).Sync(ctx)
	if err != nil {
		return
	}

	return
}

//go:embed templates/*
var templates embed.FS

func (m *Terraform) LintReport(ctx context.Context, js string) (string, error) {
	data := map[string]interface{}{}
	if err := json.Unmarshal([]byte(js), &data); err != nil {
		return "", err
	}

	// t, err := template.New("").ParseFS(templates, "templates/tflint.md.gotpl")
	t, err := template.ParseFS(templates, "templates/tflint.md.tpl")
	if err != nil {
		return "", err
	}
	var tpl bytes.Buffer
	if err = t.Execute(&tpl, data); err != nil {
		return "", err
	}

	return tpl.String(), nil
}
