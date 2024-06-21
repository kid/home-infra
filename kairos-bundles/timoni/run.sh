#!/bin/bash

set -xeu

bin=/usr/local/bin/
system=/etc/systemd/system/

mkdir -p "$bin"
cp timoni "$bin"
cp timoni-apply.sh "$bin"
cp timoni-apply.service "$system"
systemctl enable timoni-apply
