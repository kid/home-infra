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

	"github.com/google/go-github/v64/github"
	"github.com/kid/home-infra/.dagger/internal/dagger"
)

type HomeInfra struct {
	Source  *dagger.Directory // +private
	GitDir  *dagger.Directory // +private
	IsCi    bool              // +private
	GhPr    int               // +private
	GhToken *dagger.Secret    // +private
	SopsKey *dagger.Secret    // +private
}

func New(
	ctx context.Context,
	// +optional
	// +defaultPath="/"
	// +ignore=[".git", ".archived", ".devenv", ".direnv", "dagger/dagger.gen.go", "dagger/internal", "**/.terraform", "**/.terragrunt-cache"]
	source *dagger.Directory,
	// Git directory, used for commitlint.
	// +optional
	// +defaultPath="/.git"
	gitDir *dagger.Directory,
	// +optional
	ci bool,
	// GitHub event type (e.g., pull_request)
	// +optional
	ghEventName string,
	// Github event payload
	// +optional
	ghEvent *dagger.File,
	// +optional
	ghToken *dagger.Secret,
	// +optional
	sopsKey *dagger.Secret,
) (*HomeInfra, error) {
	m := &HomeInfra{
		Source:  source,
		GitDir:  gitDir,
		IsCi:    ci,
		GhToken: ghToken,
		SopsKey: sopsKey,
	}

	if ghEventName != "" && ghEvent != nil {
		m.IsCi = true

		payload, err := ghEvent.Contents(ctx)
		if err != nil {
			return nil, err
		}
		event, err := github.ParseWebHook(ghEventName, []byte(payload))
		if err != nil {
			return nil, err
		}

		if e, ok := event.(*github.PullRequestEvent); ok {
			m.GhPr = e.GetNumber()
		}
	}

	return m, nil
}

func (m *HomeInfra) Base(pkgs ...string) *dagger.Container {
	return dag.
		Wolfi().
		Container(dagger.WolfiContainerOpts{
			Packages: pkgs,
		})
}
