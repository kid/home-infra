#!/bin/bash

set -xeuo pipefail

bin=/usr/local/bin

mkdir -p "$bin"
cp timoni "$bin"

bundle_urls=$(kairos-agent config get timoni.bundles[].url | uniq)
if [ "$bundle_urls" != "null" ]; then
	for url in $bundle_urls; do
		curl -sSL "$url" | timoni bundle apply --kubeconfig=/etc/rancher/k3s/k3s.yaml -f -
	done
fi
