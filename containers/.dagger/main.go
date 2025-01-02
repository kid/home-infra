package main

import (
	"context"
	"fmt"
	"path"
	"slices"

	"golang.org/x/sync/errgroup"
	yaml "gopkg.in/yaml.v3"

	"github.com/kid/home-infra/containers/.dagger/internal/dagger"
)

type Containers struct {
	Platforms   []dagger.Platform
	Source      *dagger.Directory
	ImageSource string // +private
	Registry    string // +private
	Namespace   string // +private
}

type ContainerMetadata struct {
	App      string             `yaml:"app"`
	Channels []ContainerChannel `yaml:"channels"`
}

type ContainerChannel struct {
	Name      string            `yaml:"name,omitempty"`
	Platforms []dagger.Platform `yaml:"platforms"`
	BuildArgs []dagger.BuildArg `yaml:"buildArgs"`
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
		From("hadolint/hadolint:v2.12.0").
		WithExec([]string{}, dagger.ContainerWithExecOpts{
			UseEntrypoint: true,
			Stdin:         contents,
		}).
		Sync(ctx)

	return err
}

func (m *Containers) buildChannel(target string, channel ContainerChannel, platform dagger.Platform) *dagger.Container {
	return dag.
		Container(dagger.ContainerOpts{
			Platform: platform,
		}).
		Build(m.Source.Directory(target), dagger.ContainerBuildOpts{
			BuildArgs: channel.BuildArgs,
		})
}

func (m *Containers) Build(ctx context.Context, target string, platform dagger.Platform) error {
	meta, err := m.readMeta(ctx, target)
	if err != nil {
		return err
	}

	fmt.Printf("Meta: %v\n", meta)

	g, ctx := errgroup.WithContext(ctx)
	for _, channel := range meta.Channels {
		g.Go(func() error {
			_, err := m.buildChannel(target, channel, platform).Sync(ctx)
			return err
		})
	}

	return g.Wait()
}

func (m *Containers) Publish(ctx context.Context, target, username string, password *dagger.Secret) ([]string, error) {
	imageDigests := make([]string, 0)

	if err := m.Lint(ctx, target); err != nil {
		return imageDigests, err
	}

	meta, err := m.readMeta(ctx, target)
	for _, channel := range meta.Channels {
		platformVariants := make([]*dagger.Container, 0, len(m.Platforms))

		for _, platform := range m.Platforms {
			if !slices.Contains(channel.Platforms, platform) {
				continue
			}

			platformVariants = append(platformVariants, m.buildChannel(target, channel, platform))
		}

		version, err := platformVariants[0].Label(ctx, "org.opencontainers.image.version")
		if err != nil {
			return imageDigests, err
		}

		imageRepo := fmt.Sprintf("%s/%s/%s:%s", m.Registry, m.Namespace, meta.App, version)
		imageDigest, err := dag.
			Container().
			WithLabel("org.opencontainers.image.source", m.ImageSource).
			WithRegistryAuth(m.Registry, username, password).
			Publish(ctx, imageRepo, dagger.ContainerPublishOpts{
				PlatformVariants: platformVariants,
			})

		if err != nil {
			return imageDigests, err
		}

		imageDigests = append(imageDigests, imageDigest)
	}

	return imageDigests, err
}

func (m *Containers) readMeta(ctx context.Context, target string) (ContainerMetadata, error) {
	contents, err := m.Source.File(path.Join(target, "metadata.yaml")).Contents(ctx)
	if err != nil {
		return ContainerMetadata{}, err
	}
	meta := ContainerMetadata{}
	if err = yaml.Unmarshal([]byte(contents), &meta); err != nil {
		return ContainerMetadata{}, err
	}

	return meta, nil
}
