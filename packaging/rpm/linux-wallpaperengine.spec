Name:           linux-wallpaperengine
%global debug_package %{nil}
Version:        1.0.0
Release:        1%{?dist}
Summary:        Run Wallpaper Engine backgrounds on Linux

License:        GPL-3.0-only
URL:            https://github.com/qw0er/linux-wallpaperengine
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  dbus-devel
BuildRequires:  ffmpeg-free-devel
BuildRequires:  fftw-devel
BuildRequires:  freetype-devel
BuildRequires:  freeglut-devel
BuildRequires:  gcc-c++
BuildRequires:  glew-devel
BuildRequires:  glfw-devel
BuildRequires:  glm-devel
BuildRequires:  gmp-devel
BuildRequires:  libX11-devel
BuildRequires:  libXcursor-devel
BuildRequires:  libXinerama-devel
BuildRequires:  libXi-devel
BuildRequires:  libXrandr-devel
BuildRequires:  libXxf86vm-devel
BuildRequires:  lz4-devel
BuildRequires:  mesa-libGL-devel
BuildRequires:  mpv-devel
BuildRequires:  ninja-build
BuildRequires:  nspr-devel
BuildRequires:  nss-devel
BuildRequires:  patchelf
BuildRequires:  pkgconf-pkg-config
BuildRequires:  pulseaudio-libs-devel
BuildRequires:  SDL2-devel
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel
BuildRequires:  zlib-devel

Requires:       nspr
Requires:       nss
# RPM generates the remaining shared-library requirements from the installed ELF files.

%description
An OpenGL-based wallpaper engine for Linux that runs Wallpaper Engine assets.

%prep
%autosetup -n %{name}-%{version}

%build
cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=%{_libdir}/linux-wallpaperengine \
    -DCMAKE_SHARED_LINKER_FLAGS:STRING="-Wl,--no-as-needed -lnss3 -lssl3 -lsmime3 -lnssutil3 -lnspr4 -lplc4 -lplds4 -Wl,--as-needed" \
    -DBUILD_TESTING=OFF
cmake --build build --parallel

%install
DESTDIR=%{buildroot} cmake --install build

runtime_dir=%{buildroot}%{_libdir}/linux-wallpaperengine
# install(DIRECTORY) copies third-party ELF files without rewriting their build RPATH
# and may install them without executable permissions.
find "${runtime_dir}" -type f -exec sh -c '
    for binary do
        rpath=$(patchelf --print-rpath "$binary" 2>/dev/null) || continue
        case "$rpath" in
            *"/BUILD/"*|*::*)
                patchelf --set-rpath "\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/lib64" "$binary"
                ;;
        esac
    done
' sh {} +

install -D -m 0755 /dev/stdin \
    %{buildroot}%{_bindir}/linux-wallpaperengine <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
exec %{_libdir}/linux-wallpaperengine/linux-wallpaperengine "$@"
EOF

%files
%license LICENSE
%{_bindir}/linux-wallpaperengine
%{_libdir}/linux-wallpaperengine/
