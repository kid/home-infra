package main

import (
	"context"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

type Flux struct {
	// checkBuilder            // +private
	HomeInfra *HomeInfra // +private
}

func (m *HomeInfra) Flux() *Flux {
	return &Flux{
		HomeInfra: m,
	}
}

func (m *Flux) Diff(ctx context.Context, branch string) {
	dag.Git("https://github.com/kid/home-infra.git", dagger.GitOpts{})
}
