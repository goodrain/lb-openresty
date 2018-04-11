#!/bin/bash


# setup env
tag=`grep '^version ' VERSION | awk '{print $2}'`
name=rbd-loadbalancer


# build
docker build -t $name . || { echo "failed!"; }


# start
[[ `docker ps -a | grep $name | wc -l | xargs -I C echo C` > 0 ]] && { docker stop $name; docker rm $name; }
docker run \
--name $name \
-p 80:80 \
-p 443:443 \
-p 8081:8081 \
-p 8082:8082 \
-tid $name
sleep 2 ;[[ `docker ps | grep $name | wc -l | xargs -I C echo C` < 1 ]] && { echo "failed!"; docker logs $name; docker rm $name; }
