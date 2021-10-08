FROM alpine:3.12

# Create Alpine 3.12 (musl 1.1.24) image for building musl-based Linux ARM64v8 binaries

RUN apk update && apk upgrade && \
    apk --update --no-cache add \
       autoconf \
       automake \
       build-base \
       curl \
       ca-certificates \
       && \
    curl -fSL https://github.com/lovell/aarch64-linux-musl-crosstools/archive/3f63838c76de160b265cec5df363606314fa5117.tar.gz \
      | tar -hxz --strip-components=2 -C /

RUN addgroup -g 1000 build && \
    adduser -Dh /home/build -u 1000 -G build build

USER build
WORKDIR /home/build

ENV CHOST="aarch64-linux-musl" \
    FLAGS="-march=armv8-a"
