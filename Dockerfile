FROM alpine:latest as builder

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apk update
RUN apk add --no-cache --upgrade bash curl ncurses openssl
RUN apk add --update gcc g++ musl-dev make pcre pcre-dev openssl-dev zlib-dev readline-dev perl
RUN apk add build-base

# Lua build
ADD ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
ADD ./scripts/build-openresty /tmp/build-openresty
RUN /tmp/build-openresty

#############
# Final Image
#############

FROM alpine:latest
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

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

# Copy openresty build from first image
COPY --from=builder /tmp/openresty /tmp/openresty
ADD ./scripts/install-openresty /tmp/install-openresty

RUN /tmp/install-lua \
	&& /tmp/install-openresty \
	&& rm -f /tmp/install-lua \
	&& rm -f /tmp/install-openresty \
	&& apk del make
