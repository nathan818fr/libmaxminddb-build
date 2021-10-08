FROM alpine:3.12

# Create Alpine 3.12 (musl 1.1.24) image for building musl-based Linux x64 binaries

RUN apk update && apk upgrade && \
    apk --update --no-cache add \
       autoconf \
       automake \
       build-base

RUN addgroup -g 1000 build && \
    adduser -Dh /home/build -u 1000 -G build build

USER build
WORKDIR /home/build

ENV FLAGS="-march=westmere"
