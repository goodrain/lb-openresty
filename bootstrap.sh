#!/bin/sh

set -x

mkdir -p $OPENRESTY_HOME/nginx/conf/dynamics ; cd $OPENRESTY_HOME/nginx/conf/dynamics
mkdir -p dynamic_certs dynamic_servers dynamic_upstreams

[[ x$DEFAULT_PORT == x ]] && DEFAULT_PORT=80
sed -i "s/listen   80;/listen   $DEFAULT_PORT;/g" $OPENRESTY_HOME/nginx/conf/nginx.conf

$OPENRESTY_HOME/nginx/sbin/nginx -g "daemon off;"
