#!/bin/bash

echo building logging-view-plugin

cd /Users/emurasak/workspace/logging-view-plugin/

git checkout fix-initial-config-load

git pull origin fix-initial-config-load

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/logging-view-plugin:ou817 . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/logging-view-plugin:ou817
