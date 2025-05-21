#!/bin/bash

echo building distributed-tracing-console-plugin

cd /Users/emurasak/workspace/distributed-tracing-console-plugin

git checkout main

git pull origin main

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:latest . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:latest
