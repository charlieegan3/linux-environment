#!/usr/bin/env bash

set -euo pipefail

cd /build

# install deps to run make
dnf install --assumeyes make unzip git ansible

# open the package from the local repo and remove the zip
unzip head.zip && rm head.zip

# make the image and push it
make playbook
