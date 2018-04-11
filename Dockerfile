FROM goodrainapps/alpine:3.4

ADD /openresty.tar.gz /usr/local/

ENV OPENRESTY_HOME=/usr/local/openresty \
    NGINX_API_PORT=8081 \
    NGINX_DYUPS_PORT=8082

WORKDIR $OPENRESTY_HOME

COPY /conf $OPENRESTY_HOME/nginx/conf
COPY /lua $OPENRESTY_HOME/nginx/lua
COPY /bootstrap.sh /bootstrap.sh

CMD /bootstrap.sh
