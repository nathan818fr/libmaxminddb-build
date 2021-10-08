FROM debian:buster

# Create Debian image for cross-compiling Linux ARMv6 binaries

RUN dpkg --add-architecture armhf && \
    apt-get update -yqq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       build-essential \
       curl \
       ca-certificates \
       && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /usr/rpi-newer-crosstools && \
    curl -fSL https://github.com/rvagg/rpi-newer-crosstools/archive/eb68350c5c8ec1663b7fe52c742ac4271e3217c5.tar.gz \
      | tar -xz --strip-components=1 -C /usr/rpi-newer-crosstools

ENV PATH="/usr/rpi-newer-crosstools/x64-gcc-6.5.0/arm-rpi-linux-gnueabihf/bin:$PATH"
ENV CROSSTOOLS_SYSROOT="/usr/rpi-newer-crosstools/x64-gcc-6.5.0/arm-rpi-linux-gnueabihf/arm-rpi-linux-gnueabihf/sysroot/usr/bin"

RUN groupadd -g 1000 build && \
    useradd -md /home/build -u 1000 -g 1000 build

USER build
WORKDIR /home/build

ENV PLATFORM="linux-armv6" \
    CHOST="arm-rpi-linux-gnueabihf" \
    FLAGS="-march=armv6z -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
