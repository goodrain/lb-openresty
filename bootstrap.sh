#!/bin/sh

cd $OPENRESTY_HOME/nginx/conf/balances
mkdir -p dynamic_certs dynamic_http_servers dynamic_stream_servers dynamic_http_upstreams dynamic_stream_upstreams

$OPENRESTY_HOME/nginx/sbin/nginx
