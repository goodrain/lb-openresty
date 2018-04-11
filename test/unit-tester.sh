#!/bin/bash

# You must execute build.sh before executing this script


# setup functions
tester(){
  if [[ x$3 == x ]]; then
    echo "$1 => $2"
    r=`curl -X $1 -s $ip:$port/apiv1/$2`
  else
    echo "$1 => $3"
    r=`curl -X $1 -sd "$2" $ip:$port/apiv1/$3`
  fi
  echo "result => $r"
}


# setup variable
ip="localhost"
port="8081"
name=${1:-app1}


# testing
json1='{"name": "80.service.ns.kube.local.", "servers": ["127.0.0.1:8089"]}'
json2='{"name": "80.service.ns.kube.local.", "servers": ["127.0.0.1:8088", "127.0.0.1:8089"]}'

json3='{"name": "8085.app1.ns.kube.local.", "domain": "8085.app1.ns.kube.local.", "port": 8085, "path": "/", "options": {}, "upstream": "app1"}'
json4='{"name": "8085.app1.ns.kube.local.", "domain": "8085.app1.ns.kube.local.", "port": 8085, "path": "/", "protocol": "tls", "cert": "thiscert", "key": "thiskey", "options": {}, "upstream": "app1"}'

json5='{"name": "3360.service.ns.kube.local.", "port": 3360, "options": {}, "upstream": "app1"}'
json6='{"name": "3360.service.ns.kube.local.", "port": 3361, "options": {}, "upstream": "app1"}'

tester POST "$json1" http_upstreams/$name
tester GET http_upstreams
tester UPDATE "$json2" http_upstreams/$name
tester GET http_upstreams/$name


tester POST "$json1" stream_upstreams/$name
tester GET stream_upstreams
tester UPDATE "$json2" stream_upstreams/$name
tester GET stream_upstreams/$name


tester POST "$json3" http_servers/$name
tester GET http_servers
tester UPDATE "$json4" http_servers/$name
tester GET http_servers/$name
tester DELETE http_servers/$name


tester POST "$json5" stream_servers/$name
tester GET stream_servers
tester UPDATE "$json6" stream_servers/$name
tester GET stream_servers/$name
tester DELETE stream_servers/$name




tester DELETE http_upstreams/$name
tester DELETE stream_upstreams/$name



