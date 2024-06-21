#!/bin/bash

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

bundle_urls=$(kairos-agent config get timoni.bundles[].url | uniq)
if [ "$bundle_urls" != "null" ]; then
	for url in $bundle_urls; do
		curl -sSL "$url" | timoni bundle apply -f -
	done
fi
