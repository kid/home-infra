package main

import (
	"context"
	_ "embed"
	"path"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

//go:embed scripts/kubeconform-kustomize.sh
var kubeconformKustomize []byte

type Kube struct {
	checkBuilder            // +private
	HomeInfra    *HomeInfra // +private
}

func (m *HomeInfra) Kube() *Kube {
	return &Kube{
		HomeInfra: m,
	}
}

func (m *Kube) buildChecks(ctx context.Context) (checks []Check, err error) {
	dirs, err := Containing(ctx, m.HomeInfra.Source, "kustomization.yaml")

	for _, dir := range dirs {
		checks = append(checks, Check{
			Name: path.Join(dir, "kubeconform"),
			Check: func(ctx context.Context) error {
				_, err := m.KubeConform(dir).Sync(ctx)
				return err
			},
		})
	}

	return
}

func (m *Kube) Base() *dagger.Container {
	kubeConform := dag.Container().From("ghcr.io/yannh/kubeconform:v0.6.7-alpine")
	return m.HomeInfra.
		Base(
			"gettext=0.22.5", // contains envsubst
			"bash=5.2.37",
			"kustomize=5.4.3",
			"flux=2.3.0",
			"helm=3.16.1",
			"py3-pip",
			"git=2.46.1",
			"yq=4.44.6",
			"jq=1.7.1",
		).
		WithExec([]string{"pip3", "install", "flux-local"}).
		WithFile("/usr/bin/kubeconform", kubeConform.File("/kubeconform")).
		WithNewFile("/usr/bin/kubeconform-kustomize", string(kubeconformKustomize), dagger.ContainerWithNewFileOpts{
			Permissions: 0755,
		}).
		WithDirectory("/src/clusters", m.HomeInfra.Source.Directory("clusters")).
		WithWorkdir("/src")
}

func (m *Kube) KubeConform(
	path string,
) *dagger.Container {
	return m.Base().WithExec([]string{"kubeconform-kustomize", path})
}
