package main

import (
	"context"
	"fmt"
	"path"
	"strings"

	"github.com/kid/home-infra/containers/.dagger/internal/dagger"
)

type Containers struct {
	Platforms   []dagger.Platform
	Source      *dagger.Directory
	ImageSource string // +private
	Registry    string // +private
	Namespace   string // +private
}

func New(
	// +optional
	// +defaultPath="/"
	// +ignore=["**/*", "!containers/", "containers/.dagger", "containers/dagger.json"]
	source *dagger.Directory,
	// +optional
	// +default=["linux/amd64", "linux/arm64"]
	platforms []dagger.Platform,
	// +optional
	// +default="https://github.com/kid/home-infra"
	imageSource string,
	// +optional
	// +default="ghcr.io"
	registry string,
	// +optional
	// +default="kid/home-infra"
	namespace string,
) Containers {
	return Containers{
		Source:      source,
		Platforms:   platforms,
		ImageSource: imageSource,
		Registry:    registry,
		Namespace:   namespace,
	}
}

// Targets returns a list of container directories.
func (m *Containers) Targets(ctx context.Context) (targets []string, err error) {
	entries, err := m.Source.Glob(ctx, "**/Dockerfile")
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		targets = append(targets, path.Dir(entry))
	}

	return
}

func (m *Containers) Lint(ctx context.Context, target string) error {
	contents, err := m.Source.File(path.Join(target, "Dockerfile")).Contents(ctx)
	if err != nil {
		return err
	}

	_, err = dag.
		Container().
		From("ghcr.io/hadolint/hadolint:v2.12.0").
		WithExec([]string{}, dagger.ContainerWithExecOpts{
			UseEntrypoint: true,
			Stdin:         contents,
		}).
		Sync(ctx)

	return err
}

func (m *Containers) Build(target string, platform dagger.Platform) *dagger.Container {
	return dag.Container(dagger.ContainerOpts{Platform: platform}).Build(m.Source.Directory(target))
}

func (m *Containers) Publish(ctx context.Context, target, username string, password *dagger.Secret) (string, error) {
	if err := m.Lint(ctx, target); err != nil {
		return "", err
	}

	platformVariants := make([]*dagger.Container, 0, len(m.Platforms))
	for _, platform := range m.Platforms {
		platformVariants = append(platformVariants, m.Build(target, platform))
	}

	version, err := platformVariants[0].Label(ctx, "org.opencontainers.image.version")
	if err != nil {
		return "", err
	}

	imageRepo := fmt.Sprintf("%s/%s/%s:%s", m.Registry, m.Namespace, strings.TrimPrefix(target, "containers/"), version)

	imageDigest, err := dag.
		Container().
		WithLabel("org.opencontainers.image.source", m.ImageSource).
		WithRegistryAuth(m.Registry, username, password).
		Publish(ctx, imageRepo, dagger.ContainerPublishOpts{
			PlatformVariants: platformVariants,
		})

	if err != nil {
		return "", err
	}

	return imageDigest, err
}
