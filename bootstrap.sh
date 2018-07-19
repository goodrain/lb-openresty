#!/bin/sh

set -e

mkdir -p $OPENRESTY_HOME/nginx/conf/dynamics ; cd $OPENRESTY_HOME/nginx/conf/dynamics
mkdir -p dynamic_certs dynamic_servers dynamic_upstreams

[[ x$DEFAULT_PORT == x ]] && DEFAULT_PORT=80
sed -i "s/listen   80;/listen   $DEFAULT_PORT;/g" $OPENRESTY_HOME/nginx/conf/nginx.conf

if [ "$1"  == "bash" ];then
    exec /bin/sh
elif [ "$1" == "version" ];then
    exec echo ${VERSION}
else
    if [ "$VIPENABLE" == "true" ];then
        vrrpd -i "${VIPIFNAME:-eth0}" -n  -v $(date +%S) ${VIP:-172.17.4.88} -I ${VIP:-172.17.4.88} -O ${VIPDST:-172.17.4.254}
    fi
    exec $OPENRESTY_HOME/nginx/sbin/nginx -g "daemon off;"
fi