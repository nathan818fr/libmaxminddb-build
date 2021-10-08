FROM debian:buster

# Create Debian Buster (glibc 2.28) image for cross-compiling Linux ARM64v8 binaries

RUN dpkg --add-architecture arm64 && \
    apt-get update -yqq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       build-essential \
       crossbuild-essential-arm64 \
       && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 build && \
    useradd -md /home/build -u 1000 -g 1000 build

USER build
WORKDIR /home/build

ENV CHOST="aarch64-linux-gnu" \
    FLAGS="-march=armv8-a"
