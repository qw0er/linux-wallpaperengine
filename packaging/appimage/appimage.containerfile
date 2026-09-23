FROM ubuntu:22.04 AS build-environment

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# Ubuntu 22.04's default compiler does not provide all C++ standard-library
# features required by the current source tree, so use GCC 13 from the Ubuntu
# toolchain PPA. Everything installed here is only part of the build image.
RUN test "${TARGETARCH:-amd64}" = "amd64" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        software-properties-common \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        file \
        freeglut3-dev \
        g++-13 \
        gcc-13 \
        git \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libcups2 \
        libdbus-1-dev \
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
        librsvg2-bin \
        libsdl2-dev \
        libswresample-dev \
        libswscale-dev \
        libwayland-bin \
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
        xz-utils \
        zlib1g-dev \
    && curl --fail --location --retry 3 \
        --output /usr/local/bin/linuxdeploy.AppImage \
        https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    && curl --fail --location --retry 3 \
        --output /usr/local/bin/appimagetool.AppImage \
        https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage \
    && chmod +x /usr/local/bin/linuxdeploy.AppImage /usr/local/bin/appimagetool.AppImage \
    && rm -rf /var/lib/apt/lists/*

ENV APPIMAGE_EXTRACT_AND_RUN=1

FROM build-environment AS packager

WORKDIR /workspace
COPY . /workspace

RUN mkdir -p /cache /artifacts \
    && SOURCE_DIR=/workspace \
       OUTPUT_DIR=/artifacts \
       CACHE_DIR=/cache \
       /workspace/packaging/appimage/build-appimage-in-container.sh

# The final stage intentionally contains only the file exported by
# `podman build --output` or `docker build --output`.
FROM scratch AS artifact

COPY --from=packager /artifacts/linux-wallpaperengine-x86_64.AppImage /
