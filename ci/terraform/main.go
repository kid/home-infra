package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"dagger.io/dagger"
)

const (
	OUT_DIR      = "/out"
	PLAN_FILE    = "apply.tfplan"
	TFLINT_IMAGE = "ghcr.io/terraform-linters/tflint:v0.50.0"
)

type Terraform struct {
	// Terraform version to use
	Version string
	// Directory containing the repository source
	Source      *Directory
	InitBackend bool
}

func New(source *Directory, version Optional[string]) *Terraform {
	return &Terraform{
		Source:      source,
		Version:     version.GetOr("1.6.6"),
		InitBackend: false,
	}
}

func (m *Terraform) Init(ctx context.Context, chdir string) (*Container, error) {
	return m.Base().
		// WithFocus().
		WithExec([]string{
			fmt.Sprintf("-chdir=%s", chdir),
			"init",
			fmt.Sprintf("-backend=%t", m.InitBackend),
		}).
		Sync(ctx)
}

func (m *Terraform) Validate(ctx context.Context, chdir string) (string, error) {
	return m.Base().With(Init(chdir, false)).WithExec([]string{
		fmt.Sprintf("-chdir=%s", chdir),
		"validate",
	}).Stdout(ctx)
	//
	// init, err := m.Init(ctx, chdir)
	// if err != nil {
	// 	return "", err
	// }
	// return init.WithExec([]string{
	// 	fmt.Sprintf("-chdir=%s", chdir),
	// 	"validate",
	// }).Stdout(ctx)
}

// run tflint recursively
// func (m *Terraform) Lint(ctx context.Context) (string, error) {
// 	return dag.Container().
// 		From(TFLINT_IMAGE).
// 		WithDirectory("/data", m.Source, ContainerWithDirectoryOpts{
// 			Exclude: []string{".git", "ci", ".direnv", ".devenv"},
// 		}).
// 		WithExec([]string{"--recursive"}).
// 		Stdout(ctx)
// }

// example usage: "dagger call plan --source . --chdir fixtures"
func (m *Terraform) Plan(ctx context.Context, chdir string) (*Directory, error) {
	// init, err := m.Init(ctx, chdir)
	// if err != nil {
	// 	return nil, err
	// }
	m.InitBackend = true
	exec := m.Base().
		// WithExec([]string{fmt.Sprintf("-chdir=%s", chdir), "init", "-input=false"}).
		WithFocus().
		WithExec([]string{
			fmt.Sprintf("--terragrunt-working-dir=%s", chdir),
			"plan",
			"-detailed-exitcode",
			"-input=false",
			"-out", filepath.Join(OUT_DIR, PLAN_FILE),
		})

	output, err := exec.Stdout(ctx)
	var e *dagger.ExecError
	if errors.As(err, &e) {
		if e.ExitCode == 1 {
			return nil, err
		}
	}

	fmt.Println(output)

	out := exec.
		WithNewFile(filepath.Join(OUT_DIR, "apply.txt"), ContainerWithNewFileOpts{
			Contents: output,
		}).
		Directory(OUT_DIR)
	return out, nil
}

// func (m *Terraform) PlanOutput(ctx context.Context, chdir string) *File {
// 	return m.Plan(ctx, chdir).File("apply.txt")
// }

// example usage: "dagger call apply --directory stack"
func (m *Terraform) Apply(ctx context.Context, chdir string, plan *File) (string, error) {
	plan_path := filepath.Join(OUT_DIR, PLAN_FILE)
	return m.Base().
		WithFile(plan_path, plan).
		WithExec([]string{fmt.Sprintf("-chdir=%s", chdir), "apply", plan_path}).
		Stdout(ctx)
}

func (m *Terraform) Base() *Container {
	terragrunt := dag.HTTP("https://github.com/gruntwork-io/terragrunt/releases/download/v0.54.16/terragrunt_linux_amd64")
	return dag.Container().
		From(fmt.Sprintf("docker.io/hashicorp/terraform:%s", m.Version)).
		// WithDirectory(OUT_DIR, dag.Directory()).
		WithFile("/bin/terragrunt", terragrunt, ContainerWithFileOpts{
			Permissions: 0755,
		}).
		WithEntrypoint([]string{"/bin/terragrunt"}).
		WithMountedDirectory("/src", m.Source).
		WithWorkdir("/src")
}

func Init(chdir string, backend bool) WithContainerFunc {
	return func(ctr *Container) *Container {
		return ctr.WithExec([]string{fmt.Sprintf("--terragrunt-working-dir=%s", chdir), "init", fmt.Sprintf("-backend=%t", backend)})
	}
}

func Validate(chdir string) WithContainerFunc {
	return func(ctr *Container) *Container {
		return ctr.WithExec([]string{fmt.Sprintf("--terragrunt-working-dir=%s", chdir), "validate"})
	}
}
func Plan(chdir string) WithContainerFunc {
	return func(ctr *Container) *Container {
		return ctr.WithExec([]string{fmt.Sprintf("--terragrunt-working-dir=%s", chdir), "plan", "-input=false", "-out", PLAN_FILE})
	}
}

func (m *Terraform) Pipeline(
	ctx context.Context,
	chdir string,
	armClientId Optional[string],
	armSubscriptionId Optional[string],
	armTenantId Optional[string],
	actionsIdTokenRequestUrl Optional[string],
	actionsIdTokenRequestToken Optional[string],
) (string, error) {
	return m.Base().
		With(EnvVariables(map[string]Optional[string]{
			"ARM_CLIENT_ID":                  armClientId,
			"ARM_SUBSCRIPTION_ID":            armSubscriptionId,
			"ARM_TENANT_ID":                  armTenantId,
			"ACTIONS_ID_TOKEN_REQUEST_URL":   actionsIdTokenRequestUrl,
			"ACTIONS_ID_TOKEN_REQUEST_TOKEN": actionsIdTokenRequestToken,
		})).
		WithEnvVariable("TF_VAR_use_oidc", "true").
		With(Init(chdir, true)).
		With(Validate(chdir)).
		With(Plan(chdir)).
		Stdout(ctx)
}

func EnvVariables(envs map[string]Optional[string]) WithContainerFunc {
	return func(c *Container) *Container {
		for key, opt := range envs {
			val := opt.GetOr(os.Getenv(key))
			c = c.WithEnvVariable(key, val)
		}
		return c
	}
}

// func (m *Terraform) OnPR(ctx context.Context, chdir string) (string, error) {
// 	m.InitBackend = true
//
// }
