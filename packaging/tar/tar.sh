#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/../.." && pwd)"
dist_dir="${project_dir}/dist"
archive="${dist_dir}/linux-wallpaperengine-1.0.0-x86_64.tar.gz"

case "$(uname -m)" in
    x86_64|amd64) ;;
    *) echo "error: tar packaging currently supports x86_64 only" >&2; exit 1 ;;
esac

if command -v podman >/dev/null 2>&1; then
    container_runtime=podman
elif command -v docker >/dev/null 2>&1; then
    container_runtime=docker
else
    echo "error: Podman or Docker is required to build the tar archive" >&2
    exit 1
fi

mkdir -p -- "${dist_dir}"
"${container_runtime}" build \
    --file "${project_dir}/packaging/appimage/appimage.containerfile" \
    --target tar-artifact \
    --output "type=local,dest=${dist_dir}" \
    "${project_dir}"

test -s "${archive}"
tar -tzf "${archive}" | grep -x 'linux-wallpaperengine.AppDir/linux-wallpaperengine' >/dev/null
echo "Created ${archive}"
