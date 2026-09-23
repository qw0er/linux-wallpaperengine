#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/../.." && pwd)"
dist_dir="${project_dir}/dist"

case "$(uname -m)" in
    x86_64|amd64) ;;
    *)
        echo "error: DEB packaging currently supports amd64 only" >&2
        exit 1
        ;;
esac

if command -v podman >/dev/null 2>&1; then
    container_runtime=podman
elif command -v docker >/dev/null 2>&1; then
    container_runtime=docker
else
    echo "error: Podman or Docker is required to build the DEB" >&2
    exit 1
fi

mkdir -p -- "${dist_dir}"

echo "Building and exporting the DEB with ${container_runtime}..."
"${container_runtime}" build \
    --file "${script_dir}/deb.containerfile" \
    --target artifact \
    --output "type=local,dest=${dist_dir}" \
    "${project_dir}"

deb="${dist_dir}/linux-wallpaperengine_1.0.0-1_amd64.deb"
if [[ ! -s "${deb}" ]]; then
    echo "error: expected DEB was not created: ${deb}" >&2
    exit 1
fi

echo "Created ${deb}"
