#############
# Go Builder
#############

FROM --platform=${TARGETPLATFORM:-linux/amd64} golang:alpine as go

ENV MKCERT_VERSION=1.4.2
RUN apk add --no-cache wget git gcc g++
RUN mkdir /workspace
WORKDIR /workspace
RUN go get github.com/amacneil/dbmate
RUN wget -O mkcert.tgz "https://github.com/FiloSottile/mkcert/archive/v${MKCERT_VERSION}.tar.gz"
RUN tar -xzf mkcert.tgz
WORKDIR "/workspace/mkcert-${MKCERT_VERSION}"
RUN go build -ldflags "-X main.Version=v${MKCERT_VERSION}" -o /bin/mkcert

#############
# Nginx Builder
#############

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.12 as builder

ARG OPENRESTY_VERSION
ARG LUA_VERSION
ARG LUAROCKS_VERSION

RUN apk add --no-cache --upgrade bash curl ncurses openssl
RUN apk add --no-cache gcc g++ musl-dev make pcre pcre-dev openssl-dev zlib-dev readline-dev perl
RUN apk add --no-cache build-base

# Lua build
ADD ./scripts/build-lua /tmp/build-lua
RUN /tmp/build-lua

# Nginx build
ADD ./scripts/build-openresty /tmp/build-openresty
RUN /tmp/build-openresty

#############
# Final Image
#############

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.12
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

# Env var for bashrc
ARG OPENRESTY_VERSION
ENV OPENRESTY_VERSION=${OPENRESTY_VERSION}

RUN echo "Base: ${TARGETPLATFORM:-linux/amd64}" > /built-for-arch

# OpenResty uses LuaJIT which has a dependency on GCC
RUN apk add --no-cache gcc musl-dev curl bash figlet ncurses openssl pcre zlib apache2-utils tzdata perl readline unzip shadow \
	&& apk add --no-cache make \
	&& rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD ./.bashrc /root/.bashrc

# Copy lua and luarocks builds from first image
COPY --from=builder /tmp/lua /tmp/lua
COPY --from=builder /tmp/luarocks /tmp/luarocks
ADD ./scripts/install-lua /tmp/install-lua

# Copy openresty build from first image
COPY --from=builder /tmp/openresty /tmp/openresty
ADD ./scripts/install-openresty /tmp/install-openresty

# Copy golang built packages
COPY --from=go /bin/mkcert /bin/mkcert
COPY --from=go /go/bin/dbmate /bin/dbmate

RUN /tmp/install-lua \
	&& /tmp/install-openresty \
	&& rm -f /tmp/install-lua \
	&& rm -f /tmp/install-openresty \
	&& apk del make

LABEL org.label-schema.schema-version="1.0" \
	org.label-schema.license="MIT" \
	org.label-schema.name="alpine-nginx-full" \
	org.label-schema.description="A base image for use by Nginx Proxy Manager" \
	org.label-schema.url="https://github.com/jc21/docker-alpine-nginx-full" \
	org.label-schema.vcs-url="https://github.com/jc21/docker-alpine-nginx-full.git" \
	org.label-schema.cmd="docker run --rm -ti jc21/alpine-nginx-full:latest"
