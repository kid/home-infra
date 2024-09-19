package main

import (
	"context"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

func (m *HomeInfra) LintCommits(
	ctx context.Context,
	// Commitlint image to use.
	// +optional
	// renovate image: datasource=docker depName=commitlint/commitlint versioning=docker
	// +default="commitlint/commitlint:19.4.1"
	image string,
	// +optional
	// lower range of the commit range
	from string,
	// +optional
	// upper range of the commit range
	to string,
) (string, error) {
	args := []string{"--color", "--verbose", "--extends", "@commitlint/config-conventional"}
	if from != "" {
		args = append(args, "--from", from)
	}
	if to != "" {
		args = append(args, "--to", to)
	}
	if from == "" && to == "" {
		args = append(args, "--last")
	}

	ctr := dag.
		Container().
		From(image).
		WithDirectory("/src/.git", m.GitDir).
		WithWorkdir("/src").
		WithExec(args, dagger.ContainerWithExecOpts{UseEntrypoint: true})

	out, err := ctr.Stdout(ctx)
	if err != nil {
		return "", err
	}

	return out, nil
}
