package main

import (
	"context"

	"github.com/google/go-github/v64/github"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

type HomeInfra struct {
	Source      *dagger.Directory // +private
	IsCi        bool              // +private
	GhPr        int               // +private
	GhToken     *dagger.Secret    // +private
	TfToken     *dagger.Secret    // +private
	SopsAgeKeys *dagger.Secret    // +private
}

func New(
	ctx context.Context,
	// +optional
	// +defaultPath="/"
	// +ignore=["**/*", "!clusters/**/*"]
	source *dagger.Directory,
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
	tfToken *dagger.Secret,
	// +optional
	sopsAgeKeys *dagger.Secret,
) (*HomeInfra, error) {
	m := &HomeInfra{
		Source:      source,
		IsCi:        ci,
		GhToken:     ghToken,
		TfToken:     tfToken,
		SopsAgeKeys: sopsAgeKeys,
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
