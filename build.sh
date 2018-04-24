#!/bin/bash

# setup env
tag=`grep '^version ' VERSION | awk '{print $2}'`
name=rbd-lb

# build
docker build -t rainbond/$name:$tag . || { echo "failed!"; }

