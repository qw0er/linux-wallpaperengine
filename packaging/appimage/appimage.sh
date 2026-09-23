#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd -- "${script_dir}/../.." && pwd)"
dist_dir="${project_dir}/dist"

case "$(uname -m)" in
    x86_64|amd64) ;;
    *)
        echo "error: AppImage packaging currently supports x86_64 only" >&2
        exit 1
        ;;
esac

if command -v podman >/dev/null 2>&1; then
    container_runtime="podman"
elif command -v docker >/dev/null 2>&1; then
    container_runtime="docker"
else
    echo "error: Podman or Docker is required to build the AppImage" >&2
    exit 1
fi

mkdir -p -- "${dist_dir}"

echo "Building and exporting the AppImage with ${container_runtime}..."
"${container_runtime}" build \
    --file "${script_dir}/appimage.containerfile" \
    --target artifact \
    --output "type=local,dest=${dist_dir}" \
    "${project_dir}"

appimage="${dist_dir}/linux-wallpaperengine-x86_64.AppImage"
if [[ ! -x "${appimage}" ]]; then
    echo "error: expected AppImage was not created: ${appimage}" >&2
    exit 1
fi

echo "Validating the AppImage on the current Fedora system..."
APPIMAGE_EXTRACT_AND_RUN=1 "${appimage}" --help >/dev/null

echo "Created ${appimage}"
