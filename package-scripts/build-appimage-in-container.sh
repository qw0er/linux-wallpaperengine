#!/usr/bin/env bash

set -Eeuo pipefail

readonly source_dir="${SOURCE_DIR:-/workspace}"
readonly output_dir="${OUTPUT_DIR:-/dist}"
readonly cache_dir="${CACHE_DIR:-/cache}"
readonly work_dir=/tmp/linux-wallpaperengine-appimage
readonly build_dir="${work_dir}/build"
readonly appdir="${work_dir}/linux-wallpaperengine.AppDir"
readonly private_dir="${appdir}/usr/lib/linux-wallpaperengine"
readonly artifact_name=linux-wallpaperengine-x86_64.AppImage
readonly staged_artifact="${work_dir}/${artifact_name}"

cleanup() {
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

rm -rf -- "${work_dir}"
mkdir -p -- \
    "${build_dir}" \
    "${cache_dir}/cef" \
    "${output_dir}" \
    "${private_dir}" \
    "${appdir}/usr/bin" \
    "${appdir}/usr/share/applications" \
    "${appdir}/usr/share/icons/hicolor/256x256/apps"
ln -s -- "${cache_dir}/cef" "${build_dir}/cef"

cmake \
    -S "${source_dir}" \
    -B "${build_dir}" \
    -G Ninja \
    -DCMAKE_C_COMPILER=gcc-13 \
    -DCMAKE_CXX_COMPILER=g++-13 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS='-include memory -include optional' \
    -DBUILD_TESTING=OFF
cmake --build "${build_dir}" --parallel

build_output="${build_dir}/output"
cp -a -- "${build_output}/." "${private_dir}/"
cp -a -- "${build_dir}"/lib/libkissfft-float.so.* "${private_dir}/"

cat >"${appdir}/usr/bin/linux-wallpaperengine" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
appdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
private_dir="${appdir}/usr/lib/linux-wallpaperengine"
export LD_LIBRARY_PATH="${private_dir}:${appdir}/usr/lib:${appdir}/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
exec "${private_dir}/linux-wallpaperengine" "$@"
EOF
chmod +x "${appdir}/usr/bin/linux-wallpaperengine"

cat >"${appdir}/AppRun" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
appdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "${appdir}/usr/bin/linux-wallpaperengine" "$@"
EOF
chmod +x "${appdir}/AppRun"

cat >"${appdir}/usr/share/applications/linux-wallpaperengine.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Linux Wallpaper Engine
Comment=Run Wallpaper Engine backgrounds on Linux
Exec=linux-wallpaperengine
Icon=linux-wallpaperengine
Categories=Graphics;
Terminal=true
EOF

cat >"${work_dir}/linux-wallpaperengine.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#20242b"/>
  <circle cx="128" cy="104" r="64" fill="#4f8cff"/>
  <path d="M48 198h160l-45-58-28 34-24-27z" fill="#dce8ff"/>
  <text x="128" y="226" text-anchor="middle" font-family="sans-serif" font-size="28" font-weight="700" fill="#ffffff">LWE</text>
</svg>
EOF
rsvg-convert \
    --width 256 \
    --height 256 \
    --output "${appdir}/usr/share/icons/hicolor/256x256/apps/linux-wallpaperengine.png" \
    "${work_dir}/linux-wallpaperengine.svg"

ln -s -- usr/share/applications/linux-wallpaperengine.desktop "${appdir}/linux-wallpaperengine.desktop"
ln -s -- usr/share/icons/hicolor/256x256/apps/linux-wallpaperengine.png "${appdir}/linux-wallpaperengine.png"
ln -s -- linux-wallpaperengine.png "${appdir}/.DirIcon"

patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../lib64' "${private_dir}/linux-wallpaperengine"
patchelf --set-rpath '$ORIGIN:$ORIGIN/../lib:$ORIGIN/../lib64' "${private_dir}/liblinux-wallpaperengine-lib.so"

/usr/local/bin/linuxdeploy.AppImage \
    --appdir "${appdir}" \
    --executable "${private_dir}/linux-wallpaperengine" \
    --desktop-file "${appdir}/usr/share/applications/linux-wallpaperengine.desktop" \
    --icon-file "${appdir}/usr/share/icons/hicolor/256x256/apps/linux-wallpaperengine.png" \
    || echo "warning: linuxdeploy exited after copying dependencies; continuing" >&2

ARCH=x86_64 /usr/local/bin/appimagetool.AppImage \
    --no-appstream \
    "${appdir}" \
    "${staged_artifact}"
chmod +x "${staged_artifact}"
mv -f -- "${staged_artifact}" "${output_dir}/${artifact_name}"
