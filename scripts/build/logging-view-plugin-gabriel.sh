#!/bin/bash

echo building logging-view-plugin

read -p 'branch ' branch
read -p 'tag ' tag

cd /Users/emurasak/workspace/logging-view-plugin-gabriel/

git checkout $branch

git pull origin $branch

docker login quay.io

docker build -t quay.io/rh-ee-emurasak/logging-view-plugin:$tag . -f Dockerfile.dev --platform=linux/amd64

docker run -it --rm -d -p 9001:80 quay.io/rh-ee-emurasak/logging-view-plugin:$tag

docker push quay.io/rh-ee-emurasak/logging-view-plugin:$tag
