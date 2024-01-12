package main

import (
	"context"
	"fmt"
)

type Ci struct{}

// example usage: "dagger call container-echo --string-arg yo"
func (m *Ci) TerraformPlan(ctx context.Context, source *Directory, chdir string) (*File, error) {
	result := dag.
		Terraform(source).
		Plan(chdir)

	diff, err := result.File("plan.txt").Contents(ctx)
	if err != nil {
		return nil, err
	}

	fmt.Println(diff)

	return result.File("apply.tfplan"), nil
}

func (m *Ci) Ci(ctx context.Context, source *Directory) (string, error) {
	return dag.Terraform(source).Lint(ctx)
}
