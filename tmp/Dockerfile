FROM ubuntu:26.04

WORKDIR /app

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates git gcc g++ make cmake ninja-build \
        python3-pip autoconf automake pkg-config libltdl-dev libtool \
        ccache gperf bison libgl-dev libegl-dev shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu's apt-packaged meson (1.10.1) is too old for fontconfig 2.18.x,
# which requires >= 1.11.0.
RUN pip install --break-system-packages --no-cache-dir "meson>=1.11.0"

ENTRYPOINT ["/bin/bash"]
