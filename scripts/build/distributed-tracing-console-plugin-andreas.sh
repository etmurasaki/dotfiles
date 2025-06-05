#!/bin/bash

echo building distributed-tracing-console-plugin

read -p 'branch ' branch
read -p 'tag ' tag

cd /Users/emurasak/workspace/tracing-andreas/

git checkout $branch

git pull origin $branch

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:$tag . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/distributed-tracing-console-plugin:$tag
