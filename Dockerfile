FROM ubuntu:20.04

ENV PATH="/usr/src/arm-linux-3.3/toolchain_gnueabi-4.4.0_ARMv5TE/usr/bin:$PATH"
ENV TARGET=arm-unknown-linux-uclibcgnueabi
ENV AR=$TARGET-ar
ENV AS=$TARGET-as
ENV CC=$TARGET-gc
ENV CXX=$TARGET-g++
ENV LD=$TARGET-ld
ENV NM=$TARGET-nm
ENV RANLIB=$TARGET-ranlib
ENV STRIP=$TARGET-strip

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
  && apt-get -qq install -y \
    autoconf \
    cmake \
    ca-certificates \
    bison \
    build-essential \
    cpio \
    curl \
    file \
    flex \
    gawk \
    gettext \
    git \
    groff \
    jq \
    libtool \
    lib32z1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libyaml-dev \
    locales \
    make \
    openssl \
    pkg-config \
    python3 \
    python3-pip \
    python3-dev \
    rsync \
    texi2html \
    texinfo \
    unzip \
    zip \
  && apt-get clean \
  && locale-gen en_US.UTF-8

COPY toolchain_gnueabi-4.4.0_ARMv5TE.tgz /tmp
RUN mkdir -p /usr/src/arm-linux-3.3 \
  && tar -xzf /tmp/toolchain_gnueabi-4.4.0_ARMv5TE.tgz -C /usr/src/arm-linux-3.3 \
  && rm /tmp/toolchain_gnueabi-4.4.0_ARMv5TE.tgz

WORKDIR /app
VOLUME [ "/app" ]
