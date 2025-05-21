#!/bin/bash

echo building troubleshooting-panel-console-jenny

read -p 'branch ' branch
read -p 'tag ' tag

cd /Users/emurasak/workspace/troubleshooting-jenny/

git checkout $branch

git pull origin $branch

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:$tag . -f Dockerfile.dev --platform=linux/amd64

podman run -it --rm -d -p 9001:80 quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:$tag

podman push quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:$tag
