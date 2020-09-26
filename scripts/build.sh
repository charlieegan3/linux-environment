#!/usr/bin/env bash

set -euo pipefail

cd /build

# install deps to run make
dnf install --assumeyes make unzip git ansible

unzip head.zip

# make the image and push it
make playbook
