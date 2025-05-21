#!/bin/bash

echo building logging-view-plugin

cd /Users/emurasak/workspace/logging-view-plugin/

git checkout main

git pull origin main

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/logging-view-plugin:latest . -f Dockerfile.dev --platform=linux/amd64

podman run -it --rm -d -p 9001:80 quay.io/rh-ee-emurasak/logging-view-plugin:latest

podman push quay.io/rh-ee-emurasak/logging-view-plugin:latest
