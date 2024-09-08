package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/go-github/v64/github"
	"github.com/pkg/errors"
	"go.opentelemetry.io/otel/codes"
	"golang.org/x/oauth2"
)

const (
	KEY_FORMAT = "<!-- key=\"%s\" -->"
)

type Github struct {
	HomeInfra *HomeInfra // +private
	Owner     string     // +private
	Repo      string     // +private
}

func (m *HomeInfra) Github(
	ctx context.Context,
	// The owner of the repository
	// +default="kid"
	owner string,
	// The repository name
	// +default="home-infra"
	repo string,
) *Github {
	return &Github{
		HomeInfra: m,
		Owner:     owner,
		Repo:      repo,
	}
}

func (m *Github) getClient(ctx context.Context) (client *github.Client, err error) {
	t, err := m.HomeInfra.GhToken.Plaintext(ctx)
	if err != nil {
		return nil, err
	}

	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: t})
	tc := oauth2.NewClient(ctx, ts)

	client = github.NewClient(tc)

	return
}

func (m *Github) CreateOrUpdateComment(ctx context.Context, pr int, body string, key string) (err error) {
	ctx, span := Tracer().Start(ctx, "GitHub.CreateOrUpdateComment")
	defer func() {
		if err != nil {
			span.SetStatus(codes.Error, err.Error())
		}
		span.End()
	}()
	var commentId int64
	if key != "" {
		body = fmt.Sprintf("%s\n%s", fmt.Sprintf(KEY_FORMAT, key), body)
		commentId, err = m.FindComment(ctx, pr, key)
		if err != nil {
			return
		}
	}

	if commentId > 0 {
		err = m.UpdateComment(ctx, pr, commentId, body)
	} else {
		err = m.CreateComment(ctx, pr, body)
	}

	return
}

func (m *Github) CreateComment(ctx context.Context, pr int, body string) (err error) {
	comment := &github.IssueComment{
		Body: github.String(body),
	}
	client, err := m.getClient(ctx)
	if err != nil {
		return
	}
	_, _, err = client.Issues.CreateComment(ctx, m.Owner, m.Repo, pr, comment)
	return errors.Wrap(err, "failed to publish comment")
}

func (m *Github) DeleteComment(ctx context.Context, pr int, key string) (err error) {
	commentId, err := m.FindComment(ctx, pr, key)
	if err != nil {
		return
	}
	if commentId == 0 {
		return
	}

	client, err := m.getClient(ctx)
	if err != nil {
		return
	}
	_, err = client.Issues.DeleteComment(ctx, m.Owner, m.Repo, commentId)
	return
}

func (m *Github) UpdateComment(ctx context.Context, pr int, commentId int64, body string) (err error) {
	comment := &github.IssueComment{
		Body: github.String(body),
	}
	client, err := m.getClient(ctx)
	if err != nil {
		return
	}
	_, _, err = client.Issues.EditComment(ctx, m.Owner, m.Repo, commentId, comment)
	return errors.Wrap(err, "failed to update comment")
}

func (m *Github) FindComment(ctx context.Context, pr int, key string) (commentId int64, err error) {
	client, err := m.getClient(ctx)
	if err != nil {
		return
	}

	comments, _, err := client.Issues.ListComments(ctx, m.Owner, m.Repo, pr, &github.IssueListCommentsOptions{
		Sort:      github.String("created"),
		Direction: github.String("asc"),
	})
	if err != nil {
		return
	}

	for _, c := range comments {
		if strings.Contains(*c.Body, fmt.Sprintf(KEY_FORMAT, key)) {
			return *c.ID, nil
		}
	}

	return
}
