FROM debian:stable-slim

ENV PATH="/usr/src/arm-linux-3.3/toolchain_gnueabi-4.4.0_ARMv5TE/usr/bin:$PATH"
ENV TARGET=arm-unknown-linux-uclibcgnueabi
ENV AR=$TARGET-ar
ENV AS=$TARGET-as
ENV CC=$TARGET-gcc
ENV CXX=$TARGET-g++
ENV LD=$TARGET-ld
ENV LDSHARED="$TARGET-gcc -shared"
ENV NM=$TARGET-nm
ENV RANLIB=$TARGET-ranlib
ENV STRIP=$TARGET-strip

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libc6-i386 \
    lib32z1 \
    bzip2 \
    ca-certificates \
    curl \
    openssl \
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup

COPY sdk/toolchain_gnueabi-4.4.0_ARMv5TE.tgz sdk/gm_lib_2015-01-09-IPCAM.tgz /tmp/
RUN mkdir -p /usr/src/arm-linux-3.3 \
  && tar -xzf /tmp/toolchain_gnueabi-4.4.0_ARMv5TE.tgz -C /usr/src/arm-linux-3.3 \
  && tar -xzf /tmp/gm_lib_2015-01-09-IPCAM.tgz -C /usr/src \
  && rm /tmp/toolchain_gnueabi-4.4.0_ARMv5TE.tgz /tmp/gm_lib_2015-01-09-IPCAM.tgz

WORKDIR /app
VOLUME [ "/app" ]
