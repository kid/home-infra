package main

import (
	"context"
	"path/filepath"
	"strings"

	"github.com/kid/home-infra/.dagger/internal/dagger"
)

func Containing(ctx context.Context, dir *dagger.Directory, filename string) ([]string, error) {
	entries, err := dir.Glob(ctx, "**/"+filename)
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
