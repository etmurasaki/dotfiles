#!/bin/bash

echo building distributed-tracing-console-plugin

cd /Users/emurasak/workspace/distributed-tracing-console-plugin

git checkout release-1.0

git pull origin release-1.0

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:tracing10 . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:tracing10
