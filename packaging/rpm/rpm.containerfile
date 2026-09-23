FROM fedora:44 AS build-environment

RUN dnf \
        --setopt=install_weak_deps=False \
        --setopt=timeout=30 \
        --setopt=retries=2 \
        --disablerepo=updates \
        --disablerepo=fedora-cisco-openh264 \
        install -y \
        cmake \
        dbus-devel \
        ffmpeg-free-devel \
        fftw-devel \
        freetype-devel \
        freeglut-devel \
        gcc \
        gcc-c++ \
        glew-devel \
        glfw-devel \
        glm-devel \
        gmp-devel \
        libX11-devel \
        libXcursor-devel \
        libXinerama-devel \
        libXi-devel \
        libXrandr-devel \
        libXxf86vm-devel \
        lz4-devel \
        make \
        mesa-libGL-devel \
        mpv-devel \
        ninja-build \
        nspr-devel \
        nss-devel \
        patchelf \
        pkgconf-pkg-config \
        pulseaudio-libs-devel \
        rpm-build \
        SDL2-devel \
        wayland-devel \
        wayland-protocols-devel \
        zlib-devel \
    && dnf clean all

FROM build-environment AS packager

WORKDIR /workspace
COPY . /workspace

RUN mkdir -p /artifacts \
    && /workspace/packaging/rpm/build-rpm-in-container.sh

FROM scratch AS artifact
COPY --from=packager /artifacts/*.rpm /
