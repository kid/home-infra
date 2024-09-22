#!/bin/bash

set -x

bin=/usr/local/bin/
system=/etc/systemd/system/

mkdir -p "$bin"
cp cilium "$bin"
cp cilium-install.sh "$bin"
cp cilium-install.service "$system"
systemctl enable cilium-install
