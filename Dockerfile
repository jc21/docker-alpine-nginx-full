FROM alpine:latest as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV NGINX_VERSION=1.17.7

RUN apk update
RUN apk add --no-cache --upgrade bash curl ncurses openssl
RUN apk add --update gcc g++ musl-dev make pcre pcre-dev openssl-dev zlib-dev
RUN apk add build-base

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


#############
# Final Image
#############

FROM alpine:latest
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

ENV NGINX_VERSION=1.17.7

RUN apk update \
	&& apk add curl bash figlet ncurses openssl pcre zlib \
	&& apk add --update make \
	&& rm -rf /var/cache/apk/*

# Copy nginx build from first image
COPY --from=builder /tmp/nginx /tmp/nginx
WORKDIR /tmp/nginx
RUN make install \
	&& rm -rf /tmp/nginx

RUN apk del make
