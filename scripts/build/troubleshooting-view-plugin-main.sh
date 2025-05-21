#!/bin/bash

echo building troubleshooting-panel-console-jenny

cd /Users/emurasak/workspace/troubleshooting-panel-console-plugin/

git checkout main

git pull origin main

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:latest . -f Dockerfile.dev --platform=linux/amd64

podman run -it --rm -d -p 9001:80 quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:latest

podman push quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:latest
