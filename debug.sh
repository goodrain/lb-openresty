#!/bin/bash


# setup env
tag=`grep '^version ' VERSION | awk '{print $2}'`
name=rbd-lb
options="--network host"
[[ x`uname -a|awk '{print $1}'` == "xDarwin" ]] && options="-p 80:80 -p 443:443 -p 9091:9091"


# build
docker build -t rainbond/$name:$tag . || { echo "failed!"; }


# start
[[ `docker ps -a | grep $name | wc -l | xargs -I C echo C` > 0 ]] && { docker stop $name; docker rm $name; }
docker run \
--name $name \
$options \
-v `pwd`/conf:/usr/local/openresty/nginx/conf \
-v `pwd`/lua:/usr/local/openresty/nginx/lua \
-e HTTP_SUFFIX_URL=tvga8.goodrain.org \
-tid rainbond/$name:$tag
sleep 2 ;[[ `docker ps | grep $name | wc -l | xargs -I C echo C` < 1 ]] && { echo "failed!"; docker logs $name; docker rm $name; }

docker exec -ti $name env COLUMNS=$COLUMNS LINES=$LINES TERM=$TERM bash
