FROM ubuntu:26.04

WORKDIR /app

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        curl ca-certificates git gcc g++ make ninja-build meson pkg-config ccache \
        libx11-dev libxext-dev libxrender-dev shared-mime-info libgirepository1.0-dev \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash"]
