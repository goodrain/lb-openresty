#!/bin/bash

# setup env
tag=`grep '^version ' VERSION | awk '{print $2}'`
name=rbd-lb

# build info

branch_info=$(git branch | grep '^*' | cut -d ' ' -f 2)
buildTime=$(date +%F-%H)
git_commit=$(git log -n 1 --pretty --format=%h)
release_desc=${branch_info}-${git_commit}-${buildTime}

sed "s/__RELEASE_DESC__/${release_desc}/" Dockerfile > Dockerfile.release


# build
docker build -t rainbond/$name:$tag -f Dockerfile.release . || { echo 'failed!'; }

