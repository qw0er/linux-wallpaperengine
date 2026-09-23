FROM debian:trixie AS build-environment

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

RUN test "${TARGETARCH:-amd64}" = "amd64" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        dpkg-dev \
        freeglut3-dev \
        git \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libatspi2.0-0t64 \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libdbus-1-dev \
        libcups2t64 \
        libfftw3-dev \
        libfreetype-dev \
        libgl-dev \
        libglew-dev \
        libglfw3-dev \
        libglm-dev \
        libglu1-mesa-dev \
        libgmp-dev \
        liblz4-dev \
        libmpv-dev \
        libnspr4 \
        libnss3 \
        libpulse-dev \
        libsdl2-dev \
        libswresample-dev \
        libswscale-dev \
        libwayland-dev \
        libxcomposite1 \
        libxcursor-dev \
        libxdamage1 \
        libxi-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxxf86vm-dev \
        ninja-build \
        patchelf \
        pkg-config \
        python3 \
        wayland-protocols \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

FROM build-environment AS packager

WORKDIR /workspace
COPY . /workspace

RUN mkdir -p /artifacts \
    && /workspace/packaging/deb/build-deb-in-container.sh

FROM scratch AS artifact
COPY --from=packager /artifacts/*.deb /
