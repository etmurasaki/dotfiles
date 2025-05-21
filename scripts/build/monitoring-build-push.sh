#!/bin/bash

echo building monitoring-plugin

read -p 'branch ' branch
read -p 'tag ' tag

cd /Users/emurasak/workspace/monitoring-plugin/

git checkout $branch

git pull origin $branch

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/monitoring-plugin:$tag . -f Dockerfile.dev --platform=linux/amd64

podman run -it --rm -d -p 9001:80 quay.io/rh-ee-emurasak/monitoring-plugin:$tag

podman push quay.io/rh-ee-emurasak/monitoring-plugin:$tag
