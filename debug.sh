#!/bin/bash

set -x
cd ..

docker build -t lb .

[[ `docker ps -a | grep lb | wc -l | xargs -I C echo C` > 0 ]] && { docker stop lb; docker rm lb; }
docker run \
--name lb \
-p 80:80 \
-p 443:443 \
-p 8081:8081 \
-p 8082:8082 \
-v `pwd`/conf:/usr/local/openresty/nginx/conf \
-v `pwd`/lua:/usr/local/openresty/nginx/lua \
-tid lb
sleep 2 ;[[ `docker ps | grep lb | wc -l | xargs -I C echo C` < 1 ]] && { docker logs lb; docker rm lb; }

docker exec -ti lb env COLUMNS=$COLUMNS LINES=$LINES TERM=$TERM bash
