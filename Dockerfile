FROM alpine:latest as builder

ENV NGINX_VERSION=1.17.7
ENV OPENSSL_VERSION=1.1.1d

RUN apk update \
	&& apk add --no-cache --upgrade bash curl ncurses openssl \
	&& apk add --update gcc g++ musl-dev \
	&& rm -rf /var/cache/apk/*

# Nginx build
WORKDIR /tmp
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
RUN tar -xzf nginx-${NGINX_VERSION}.tar.gz
RUN mv /tmp/nginx-${NGINX_VERSION} /tmp/nginx
WORKDIR /tmp/nginx

RUN ./configure \
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
	--with-compat \
	--with-file-aio \
	--with-threads \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module

RUN make

# Openssl build
WORKDIR /tmp
RUN wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
RUN tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
RUN mv /tmp/openssl-${OPENSSL_VERSION} /tmp/openssl
WORKDIR /tmp/openssl
RUN ./config
RUN make test


#############
# Final Image
#############

FROM alpine:latest
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

RUN apk update \
	&& apk add curl bash figlet ncurses openssl \
	&& rm -rf /var/cache/apk/*

# Openssl custom
COPY --from=builder /tmp/openssl /tmp/openssl
ADD .bashrc /root/.bashrc
WORKDIR /tmp/openssl
RUN make install \
	&& ldconfig \
	&& openssl version \
	&& rm -rf /tmp/openssl

# Copy nginx build from first image
COPY --from=builder /tmp/nginx /tmp/nginx
WORKDIR /tmp/nginx
RUN make install \
	&& rm -rf /tmp/nginx
