FROM goodrainapps/alpine:3.4

ADD /openresty.tar.gz /usr/local/

ENV OPENRESTY_HOME=/usr/local/openresty \
    HTTP_SUFFIX_URL=kube.local.com

WORKDIR $OPENRESTY_HOME

COPY /conf $OPENRESTY_HOME/nginx/conf
COPY /lua $OPENRESTY_HOME/nginx/lua
COPY /bootstrap.sh /bootstrap.sh

CMD /bootstrap.sh
