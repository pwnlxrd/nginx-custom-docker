FROM alpine:latest
LABEL maintainer="pwnlxrd git.pwndev.com"
ENV NGINX_VERSION 1.21.3
RUN set -x \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk add --no-cache --virtual .build-deps \
            gcc \
        build-base \
            libc-dev \
            make \
            linux-headers \
            curl \
        pcre \
        pcre-dev \
        ca-certificates \
        openssl \
        openssl-dev \
        libressl \
        libressl-dev \
    && mkdisr/src \
    && curl -LSs https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar xzf - -C /usr/src \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && CNF="\
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --user=nginx \
            --group=nginx \
            --without-http_gzip_module \
            --with-pcre-jit \
            --with-threads \
            --with-compat \
            --with-stream \
            --with-file-aio \
            --with-http_auth_request_module \
            --with-http_ssl_module \
            --with-http_v2_module \
    " \
# Собираем
    && ./configure $CNF \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /usr/src/ \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && apk add --no-cache tzdata \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80 443
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]