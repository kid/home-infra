#!/bin/sh

set -e

format="${FORMAT:-pretty}"

kustomize build "$@" | kubeconform \
  -strict \
  -verbose \
  -summary \
  -output "$format" \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  -schema-location 'https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/v3/apis__apiextensions.k8s.io__v1_openapi.json'
