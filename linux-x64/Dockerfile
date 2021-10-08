FROM debian:stretch

# Create Debian Stretch (glibc 2.24) image for building Linux x64 binaries

RUN apt-get update -yqq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       build-essential \
       && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 build && \
    useradd -md /home/build -u 1000 -g 1000 build

USER build
WORKDIR /home/build

ENV PLATFORM="linux-x64" \
    FLAGS="-march=westmere"
