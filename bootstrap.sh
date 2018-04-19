#!/bin/sh

cd $OPENRESTY_HOME/nginx

mkdir -p conf lua

[[ `ls lua|wc -l` == 0 ]] && /bin/cp -rf $OPENRESTY_HOME/nginx/lua.default/* lua/

[[ `ls conf|wc -l` == 0 ]] && {
  /bin/cp -rf $OPENRESTY_HOME/nginx/conf.default/* conf/
  cd $OPENRESTY_HOME/nginx/conf/balances
  mkdir -p dynamic_certs dynamic_http_servers dynamic_stream_servers dynamic_upstreams
}

exec $OPENRESTY_HOME/nginx/sbin/nginx -g "daemon off;"
