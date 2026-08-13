FROM ubuntu:26.04

WORKDIR /app

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        curl ca-certificates git gcc g++ make cmake ninja-build nasm meson \
        autoconf automake pkg-config libltdl-dev libtool ccache \
        libx11-dev libxext-dev libxrender-dev shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]
