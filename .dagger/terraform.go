package main

import (
	"context"
	"github.com/kid/home-infra/.dagger/internal/dagger"
)

func (m *HomeInfra) TfLint(ctx context.Context) (string, error) {
	ctr := dag.Container().From("ghcr.io/terraform-linters/tflint:latest").
		WithDirectory("/src", m.Source).
		WithWorkdir("/src").
		WithExec([]string{"--recursive", "--minimum-failure-severity=error"}, dagger.ContainerWithExecOpts{UseEntrypoint: true})
	out, err := ctr.Stdout(ctx)
	if err != nil {
		out, err = ctr.Stderr(ctx)
		if err != nil {
			return "", err
		}
	}

	return out, err
}
