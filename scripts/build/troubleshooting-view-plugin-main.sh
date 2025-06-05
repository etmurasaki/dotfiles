#!/bin/bash

echo building troubleshooting-panel-console-main

cd /Users/emurasak/workspace/allan/

git checkout coo-981

git pull origin coo-981

podman login quay.io

podman build -t quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:coo-981 . -f Dockerfile.dev --platform=linux/amd64

podman push quay.io/rh-ee-emurasak/troubleshooting-panel-console-plugin:coo-981
