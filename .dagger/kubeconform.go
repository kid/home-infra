package main

import (
	"context"
	"fmt"
	"github.com/kid/home-infra/.dagger/internal/dagger"
	"strings"

	"golang.org/x/sync/errgroup"
)

func (m *HomeInfra) KubeConform(
	path string,
) *dagger.Container {
	kubeConform := dag.Container().From("ghcr.io/yannh/kubeconform:v0.6.7-alpine")
	return m.base([]string{"kustomize", "curl"}).
		WithFile("/usr/local/bin/kubeconform", kubeConform.File("/kubeconform")).
		WithDirectory("/src", m.Source).
		WithWorkdir("/src").
		WithExec([]string{
			"kubeconform",
			"-schema-location",
			"default",
			"-schema-location",
			"https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
			"-ignore-missing-schemas",
			"-strict",
			"-verbose",
			"-summary",
			path,
		})
}

func (m *HomeInfra) KubeConformCluster(
	ctx context.Context,
	// +default="talos.kidibox.net"
	clusterName string,
) ([]string, error) {
	files, err := m.Source.Glob(ctx, fmt.Sprintf("clusters/%s/**/kustomization.yaml", clusterName))
	if err != nil {
		return nil, err
	}

	folders := make([]string, 0, len(files))
	for _, file := range files {
		folders = append(folders, strings.TrimSuffix(file, "/kustomization.yaml"))
	}

	results := make([]string, len(folders))
	var g errgroup.Group
	for i, path := range folders {
		g.Go(func() error {
			out, err := m.KubeConform(path).Stdout(ctx)
			if err != nil {
				return err
			}
			results[i] = out
			return err
		})
	}

	err = g.Wait()
	if err != nil {
		return nil, err
	}

	return results, err
}
