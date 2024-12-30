#!/usr/bin/env bash

set -euo pipefail

format="${FORMAT:-pretty}"

kustomizeArgs=(
	--enable-helm
	--load-restrictor=LoadRestrictionsNone
)
kubeconformArgs=(
	-strict
	-verbose
	-summary
	-output "$format"
	-schema-location default
	-schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
	-schema-location 'https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/v3/apis__apiextensions.k8s.io__v1_openapi.json'
)

kustomize build "${kustomizeArgs[@]}" "$@" | yq "del(.sops)" | kubeconform "${kubeconformArgs[@]}"
