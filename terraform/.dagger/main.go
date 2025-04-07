package main

import (
	"bytes"
	"context"
	"embed"
	"encoding/json"
	"fmt"
	"path"
	"text/template"
	"time"

	"github.com/kid/home-infra/terraform/.dagger/internal/dagger"
)

const (
	TF_BINARY = "tofu"
)

type Terraform struct {
	Source      *dagger.Directory
	Ctr         *dagger.Container
	Token       *dagger.Secret // +private
	SopsAgeKeys *dagger.Secret // +private
	IsCi        bool           // +private
}

func New(
	ctx context.Context,
	// +optional
	// +defaultPath="/"
	// +ignore=["**/*", "!secrets/", "!terraform/", "terraform/.dagger", "terraform/dagger.json", "!clusters/", "clusters/.dagger", "clusters/dagger.json", "**/.terraform", "**/.terragrunt-cache"]
	source *dagger.Directory,
	// +optional
	token *dagger.Secret,
	// +optional
	sopsAgeKeys *dagger.Secret,
	// +optional
	isCi bool,
) *Terraform {
	return &Terraform{
		Source:      source,
		Token:       token,
		SopsAgeKeys: sopsAgeKeys,
		IsCi:        isCi,
	}
}

// Targets returns a list of terraform stacks
func (m *Terraform) Targets(ctx context.Context) (targets []string, err error) {
	entries, err := m.Source.Glob(ctx, "**/.terraform.lock.hcl")
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		targets = append(targets, path.Dir(entry))
	}

	return
}

func (m *Terraform) Base() *dagger.Container {
	ctr := dag.
		Wolfi().
		Container(dagger.WolfiContainerOpts{
			Packages: []string{
				"opentofu=1.9.0",
				"tflint=0.53.0",
			},
		})

	if !m.IsCi {
		ctr = ctr.
			WithMountedCache("/.terraform.d/plugin-cache", dag.CacheVolume(fmt.Sprintf("%s-plugin-cache", TF_BINARY))).
			WithEnvVariable("TF_PLUGIN_CACHE_DIR", "/.terraform.d/plugin-cache")
	}

	ctr = ctr.
		WithEnvVariable("TF_IN_AUTOMATION", "true").
		WithDirectory("/src", m.Source).
		WithWorkdir("/src")

	if m.Token != nil {
		ctr = ctr.WithSecretVariable("TF_TOKEN_app_terraform_io", m.Token)
	}

	if m.SopsAgeKeys != nil {
		ctr = ctr.WithMountedSecret("/root/.config/sops/age/keys.txt", m.SopsAgeKeys)
	}

	return ctr
}

func (m *Terraform) Fmt(ctx context.Context) (err error) {
	_, err = m.Base().WithExec([]string{TF_BINARY, "fmt", "-recursive", "-diff", "-check"}).Sync(ctx)
	// if err != nil {
	// 	if execError, ok := err.(*dagger.ExecError); ok {
	// 		return &CheckError{
	// 			Markdown: "### `terraform fmt`:\n```diff\n" + execError.Stdout + "\n```",
	// 			original: err,
	// 		}
	// 	}
	// }

	return
}

func (m *Terraform) FmtFix(ctx context.Context) (dir *dagger.Directory, err error) {
	ctr, err := m.Base().WithExec([]string{TF_BINARY, "fmt", "-recursive", "-diff"}).Sync(ctx)
	if err != nil {
		return
	}

	return ctr.Directory("/src"), err
}

func (m *Terraform) Lint(ctx context.Context) error {
	args := []string{"tflint", "--recursive", "--minimum-failure-severity=warning"}
	if m.IsCi {
		args = append(args, "--format", "json")
	} else {
		args = append(args, "--color")
	}

	_, err := m.Base().WithExec(args).Sync(ctx)
	// if execError, ok := err.(*dagger.ExecError); ok {
	// 	md, err := m.LintReport(ctx, execError.Stdout)
	// 	if err != nil {
	// 		return errors.Join(err, execError)
	// 	}
	// 	return &CheckError{
	// 		Markdown: md,
	// 		original: execError,
	// 	}
	// }

	return err
}

func (m *Terraform) LintFix(ctx context.Context) (*dagger.Directory, error) {
	ctr, err := m.Base().WithExec([]string{"tflint", "--color", "--recursive", "--fix", "--force"}).Sync(ctx)
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
) (*dagger.Container, error) {
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
	ctr, err := m.Base().WithExec(args).Sync(ctx)
	if err != nil {
		return nil, err
	}
	return ctr, nil
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
	if m.IsCi {
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
	if m.IsCi {
		args = append(args, "-json")
	}
	ctr, err = ctr.
		WithEnvVariable("CACHE_BUSTER", fmt.Sprintf("%d", time.Now().Unix())).
		WithExec(args).Sync(ctx)
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
	if m.IsCi {
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

func (m *Terraform) tfcFile(chdir string) dagger.WithContainerFunc {
	return func(ctr *dagger.Container) *dagger.Container {
		_, chdir = path.Split(chdir)
		tfc, err := renderTfcFile("kid", "home-infra", chdir)
		if err != nil {
			panic(err)
		}

		return ctr.WithNewFile(path.Join(chdir, "tfc.tf"), tfc)
	}
}

func renderTfcFile(organization, project, name string) (string, error) {
	data := struct {
		Organization string
		Project      string
		Name         string
	}{
		Organization: organization,
		Project:      project,
		Name:         name,
	}

	t, err := template.ParseFS(templates, "templates/tfc.tf.tpl")
	if err != nil {
		return "", err
	}
	var tpl bytes.Buffer
	if err = t.Execute(&tpl, data); err != nil {
		return "", err
	}

	return tpl.String(), nil
}
