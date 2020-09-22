#!/usr/bin/env bash

set -euo pipefail

set -exo pipefail

cd /build

# install deps to run make
dnf install --assumeyes make git ansible

# make the image and push it
make playbook
