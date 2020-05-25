FROM alpine:latest as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV NGINX_VERSION=1.15.8.3
# Note: OpenResty does not support Lua >= 5.2
ENV LUA_VERSION=5.1.5
ENV LUAROCKS_VERSION=3.3.1

RUN apk update
RUN apk add --no-cache --upgrade bash curl ncurses openssl
RUN apk add --update gcc g++ musl-dev make pcre pcre-dev openssl-dev zlib-dev readline-dev perl
RUN apk add build-base

# Lua build
ADD ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
ADD ./scripts/build-nginx /tmp/build-nginx
RUN /tmp/build-nginx

#############
# Final Image
#############

FROM alpine:latest
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

ENV NGINX_VERSION=1.15.8.3
# Note: OpenResty does not support Lua >= 5.2
ENV LUA_VERSION=5.1.5
ENV LUAROCKS_VERSION=3.3.1

# OpenResty uses LuaJIT which has a dependency on GCC
RUN apk update \
	&& apk add gcc musl-dev curl bash figlet ncurses openssl pcre zlib apache2-utils tzdata perl readline unzip \
	&& apk add --update make \
	&& rm -rf /var/cache/apk/*

ADD ./.bashrc /root/.bashrc

# Copy lua and luarocks builds from first image
COPY --from=builder /tmp/lua /tmp/lua
COPY --from=builder /tmp/luarocks /tmp/luarocks
ADD ./scripts/install-lua /tmp/install-lua

# Copy nginx build from first image
COPY --from=builder /tmp/nginx /tmp/nginx
ADD ./scripts/install-nginx /tmp/install-nginx

RUN /tmp/install-lua \
    && /tmp/install-nginx \
	&& rm -f /tmp/install-lua \
	&& rm -f /tmp/install-nginx \
	&& apk del make
