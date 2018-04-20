FROM goodrainapps/alpine:3.4

ADD /openresty.tar.gz /usr/local/

ENV OPENRESTY_HOME=/usr/local/openresty \
    HTTP_SUFFIX_URL=rainbond.goodrain.local

WORKDIR $OPENRESTY_HOME

COPY /conf $OPENRESTY_HOME/nginx/conf.default
COPY /lua $OPENRESTY_HOME/nginx/lua.default
COPY /bootstrap.sh /bootstrap.sh

CMD /bootstrap.sh
