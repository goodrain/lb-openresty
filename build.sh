#!/bin/bash


# setup env
tag=`grep '^version ' VERSION | awk '{print $2}'`
name=rbd-lb
options="--network host"
[[ x`uname -a|awk '{print $1}'` == "xDarwin" ]] && options="-p 80:80 -p 443:443 -p 9091:9091"


# build
docker build -t rainbond/$name:$tag . || { echo "failed!"; }

