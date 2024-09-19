package main

import (
	"context"

	"github.com/kid/home-infra/.github/internal/dagger"
)

type CI struct {
	Gha *dagger.Gha // +private
}

func New(
	ctx context.Context,
	// The home-infra repository
	// +optional
	// +defaultPath="/"
	// +ignore=["**", "!.github"]
	repository *dagger.Directory,
) (ci *CI, err error) {
	version, err := dag.Version(ctx)
	if err != nil {
		return nil, err
	}

	ci = new(CI)

	ci.Gha = dag.Gha(dagger.GhaOpts{
		DaggerVersion: version,
		Repository:    repository,
	})

	return
}

func (ci *CI) WithPipeline(
	// Pipeline name
	name string,
	// Pipeline command
	command string,
) *CI {
	opts := dagger.GhaWithPipelineOpts{
		OnPushBranches:              []string{"main"},
		OnPullRequestOpened:         true,
		OnPullRequestReopened:       true,
		OnPullRequestSynchronize:    true,
		OnPullRequestReadyForReview: true,
		Secrets:                     []string{"GITHUB_TOKEN"},
		Permissions:                 []dagger.GhaPermission{dagger.WriteIssues, dagger.WritePullRequests},
	}
	ci.Gha = ci.Gha.WithPipeline(name, command, opts)
	return ci
}

// Generate Github Actions to call our Dagger pipelines
func (ci *CI) Generate() *dagger.Directory {
	return ci.
		WithPipeline("commitlint", "lint-commits --from '${{ github.event.pull_request.head.sha }}~${{ github.event.pull_request.commits }}' --to '${{ github.event.pull_request.head.sha }}'").
		WithPipeline("check", "--gh-token=env:GITHUB_TOKEN --gh-event-name '${{ github.event_name }}' --gh-event '${{ github.event_path }}' check").
		Gha.Config()
}
