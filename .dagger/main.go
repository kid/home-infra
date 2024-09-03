// A generated module for HomeInfra functions
//
// This module has been generated via dagger init and serves as a reference to
// basic module structure as you get started with Dagger.
//
// Two functions have been pre-created. You can modify, delete, or add to them,
// as needed. They demonstrate usage of arguments and return types using simple
// echo and grep commands. The functions can be called from the dagger CLI or
// from one of the SDKs.
//
// The first line in this comment block is a short description line and the
// rest is a long description with more detail on the module's purpose or usage,
// if appropriate. All modules should have a short description.

package main

import (
	"context"
	"github.com/kid/home-infra/.dagger/internal/dagger"
)

type HomeInfra struct {
	// +pivate
	Source *dagger.Directory
	// +pivate
	GitDir *dagger.Directory
}

func New(
	ctx context.Context,
	// +optional
	// +defaultPath="/"
	// +ignore=[".git", ".devenv", ".direnv", "dagger/dagger.gen.go", "dagger/internal", "**/.terraform", "**/.terragrunt-cache"]
	source *dagger.Directory,
	// Git directory, used for commitlint.
	// +optional
	// +defaultPath="/.git"
	gitDir *dagger.Directory,
) (*HomeInfra, error) {
	return &HomeInfra{
		Source: source,
		GitDir: gitDir,
	}, nil
}

func (m *HomeInfra) base(pkgs []string) *dagger.Container {
	ctr := dag.Container().From("alpine:edge")

	if len(pkgs) > 0 {
		ctr = ctr.WithExec(append([]string{"apk", "add", "--no-cache"}, pkgs...))
	}

	return ctr
}
