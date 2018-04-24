#!/bin/sh

set -x

cd $OPENRESTY_HOME/nginx/conf/dynamics
mkdir -p dynamic_certs dynamic_servers dynamic_upstreams

exec $OPENRESTY_HOME/nginx/sbin/nginx -g "daemon off;"
