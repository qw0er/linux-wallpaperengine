#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/../.." && pwd)"
dist_dir="${project_dir}/dist"

case "$(uname -m)" in
    x86_64|amd64) ;;
    *)
        echo "error: RPM packaging currently supports x86_64 only" >&2
        exit 1
        ;;
esac

if command -v podman >/dev/null 2>&1; then
    container_runtime=podman
elif command -v docker >/dev/null 2>&1; then
    container_runtime=docker
else
    echo "error: Podman or Docker is required to build the RPM" >&2
    exit 1
fi

mkdir -p -- "${dist_dir}"

echo "Building and exporting the RPM with ${container_runtime}..."
"${container_runtime}" build \
    --file "${script_dir}/rpm.containerfile" \
    --target artifact \
    --output "type=local,dest=${dist_dir}" \
    "${project_dir}"

version=1.0.0
rpm="${dist_dir}/linux-wallpaperengine-${version}-1.fc44.x86_64.rpm"
if [[ ! -s "${rpm}" ]]; then
    echo "error: expected RPM was not created: ${rpm}" >&2
    exit 1
fi

echo "Created ${rpm}"
