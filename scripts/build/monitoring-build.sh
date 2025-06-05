#!/bin/bash

echo building monitoring-plugin

read -p 'tag ' tag

docker build -t quay.io/rh-ee-emurasak/monitoring-plugin:$tag . -f Dockerfile.dev --platform=linux/amd64