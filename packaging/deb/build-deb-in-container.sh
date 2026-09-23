#!/usr/bin/env bash

set -Eeuo pipefail

readonly source_dir=/workspace
readonly work_dir=/tmp/linux-wallpaperengine-deb
readonly build_dir="${work_dir}/build"
readonly package_dir="${work_dir}/debian/linux-wallpaperengine"
readonly private_dir="${package_dir}/usr/lib/linux-wallpaperengine"
readonly artifact=/artifacts/linux-wallpaperengine_1.0.0-1_amd64.deb

cleanup() {
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

rm -rf -- "${work_dir}"
mkdir -p -- "${build_dir}" "${private_dir}" "${package_dir}/usr/bin" \
    "${package_dir}/usr/share/doc/linux-wallpaperengine" "${package_dir}/DEBIAN"

cat >"${work_dir}/debian/control" <<'EOF'
Source: linux-wallpaperengine
Section: graphics
Priority: optional
Maintainer: linux-wallpaperengine maintainers <noreply@github.com>

Package: linux-wallpaperengine
Architecture: amd64
Description: Run Wallpaper Engine backgrounds on Linux
EOF

cmake -S "${source_dir}" -B "${build_dir}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF
cmake --build "${build_dir}" --parallel

cp -a -- "${build_dir}/output/." "${private_dir}/"
cp -a -- "${build_dir}"/lib/libkissfft-float.so.* "${private_dir}/"

# The executable and the project library must resolve the private CEF and
# kissfft libraries. Third-party binaries are changed only if they retain a
# build path in their RPATH.
patchelf --set-rpath '$ORIGIN:$ORIGIN/lib:$ORIGIN/lib64' \
    "${private_dir}/linux-wallpaperengine" \
    "${private_dir}/liblinux-wallpaperengine-lib.so"
while IFS= read -r -d '' binary; do
    rpath="$(patchelf --print-rpath "${binary}" 2>/dev/null)" || continue
    case "${rpath}" in
        *"${build_dir}"*|*::*)
            patchelf --set-rpath '$ORIGIN:$ORIGIN/lib:$ORIGIN/lib64' "${binary}"
            ;;
    esac
done < <(find "${private_dir}" -type f -print0)

cat >"${package_dir}/usr/bin/linux-wallpaperengine" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
exec /usr/lib/linux-wallpaperengine/linux-wallpaperengine "$@"
EOF
chmod 0755 "${package_dir}/usr/bin/linux-wallpaperengine"
install -m 0644 "${source_dir}/LICENSE" \
    "${package_dir}/usr/share/doc/linux-wallpaperengine/copyright"

# Give dpkg-shlibdeps dependency information for libraries shipped in this
# package. -x excludes these self-dependencies from the final Depends field.
cat >"${work_dir}/debian/shlibs.local" <<'EOF'
libcef 0 linux-wallpaperengine (>= 1.0.0-1)
liblinux-wallpaperengine-lib 0 linux-wallpaperengine (>= 1.0.0-1)
libEGL 0 linux-wallpaperengine (>= 1.0.0-1)
libGLESv2 0 linux-wallpaperengine (>= 1.0.0-1)
libvk_swiftshader 0 linux-wallpaperengine (>= 1.0.0-1)
libkissfft-float 131 linux-wallpaperengine (>= 1.0.0-1)
EOF

# Generate system dependencies from every shipped ELF file. Unresolved
# libraries remain fatal; no missing-library suppression is used.
mapfile -d '' -t elf_files < <(find "${private_dir}" -type f -print0)
shlib_args=()
for binary in "${elf_files[@]}"; do
    if readelf -h "${binary}" >/dev/null 2>&1; then
        shlib_args+=("-e${binary}")
    fi
done
if [[ "${#shlib_args[@]}" -eq 0 ]]; then
    echo "error: no ELF files found in package" >&2
    exit 1
fi
shlib_output="$(cd "${work_dir}" && dpkg-shlibdeps -O -L"${work_dir}/debian/shlibs.local" \
    -l"${private_dir}" -xlinux-wallpaperengine "${shlib_args[@]}")"
depends="${shlib_output#shlibs:Depends=}"
if [[ "${depends}" == "${shlib_output}" || -z "${depends}" ]]; then
    echo "error: dpkg-shlibdeps did not produce dependencies" >&2
    exit 1
fi

cat >"${package_dir}/DEBIAN/control" <<EOF
Package: linux-wallpaperengine
Version: 1.0.0-1
Section: graphics
Priority: optional
Architecture: amd64
Maintainer: linux-wallpaperengine maintainers <noreply@github.com>
Depends: ${depends}, bash, libnspr4, libnss3
Description: Run Wallpaper Engine backgrounds on Linux
 An OpenGL-based wallpaper engine for Linux that runs Wallpaper Engine assets.
EOF

dpkg-deb --build --root-owner-group "${package_dir}" "${artifact}"
