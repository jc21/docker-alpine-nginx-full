FROM alpine:latest as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV NGINX_VERSION=1.17.10

RUN apk update
RUN apk add --no-cache --upgrade bash curl ncurses openssl
RUN apk add --update gcc g++ musl-dev make pcre pcre-dev openssl-dev zlib-dev
RUN apk add build-base

# Nginx build
ADD ./scripts/build-nginx /tmp/build-nginx
RUN /tmp/build-nginx

#############
# Final Image
#############

FROM alpine:latest
LABEL maintainer="Jamie Curnow <jc@jc21.com>"

ENV NGINX_VERSION=1.17.10

RUN apk update \
	&& apk add curl bash figlet ncurses openssl pcre zlib apache2-utils tzdata \
	&& apk add --update make \
	&& rm -rf /var/cache/apk/*

ADD ./.bashrc /root/.bashrc

# Copy nginx build from first image
COPY --from=builder /tmp/nginx /tmp/nginx
ADD ./scripts/install-nginx /tmp/install-nginx
RUN /tmp/install-nginx \
	&& rm -f /tmp/install-nginx \
	&& apk del make
