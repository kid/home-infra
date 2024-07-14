#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kairos-agent config get cilium.values > /tmp/cilium-values.yaml
cilium status || cilium install cilium -n kube-system  -f /tmp/cilium-values.yaml
cilium status --wait
