#!/bin/bash

echo building monitoring-plugin

cd /Users/emurasak/workspace/monitoring-plugin-build-only/

git checkout add-error-boundary-to-variable-list

git pull origin add-error-boundary-to-variable-list

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/monitoring-plugin:gabriel . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/monitoring-plugin:gabriel
