package main

import (
	"context"
	"github.com/kid/home-infra/.dagger/internal/dagger"
	"path/filepath"
	"strings"
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
	args := []string{"--color", "--verbose"}
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
		WithFile("/src/.commitlintrc.ts", m.Source.File("/.commitlintrc.ts")).
		WithWorkdir("/src").
		WithExec(args, dagger.ContainerWithExecOpts{UseEntrypoint: true})

	out, err := ctr.Stdout(ctx)
	if err != nil {
		return "", err
	}

	return out, nil
}

func (m *HomeInfra) Containing(ctx context.Context, filename string) ([]string, error) {
	entries, err := m.Source.Glob(ctx, "**/"+filename)
	if err != nil {
		return nil, err
	}

	var parents []string
	for _, entry := range entries {
		entry = filepath.Clean(entry)
		parent := strings.TrimSuffix(entry, filename)
		if parent == "" {
			parent = "."
		}
		parents = append(parents, parent)
	}

	return parents, nil
}
