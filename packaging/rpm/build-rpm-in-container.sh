#!/usr/bin/env bash

set -Eeuo pipefail

readonly source_dir=/workspace
readonly work_dir=/tmp/linux-wallpaperengine-rpm
readonly rpm_topdir="${work_dir}/rpmbuild"
readonly source_stage="${work_dir}/linux-wallpaperengine-source"
readonly artifact_dir=/artifacts
readonly version=1.0.0

cleanup() {
    rm -rf -- "${work_dir}"
}
trap cleanup EXIT

rm -rf -- "${work_dir}"
mkdir -p -- "${source_stage}/linux-wallpaperengine-${version}" "${rpm_topdir}" "${artifact_dir}"
mkdir -p -- "${rpm_topdir}/SOURCES"
cp -a -- "${source_dir}/." "${source_stage}/linux-wallpaperengine-${version}/"
rm -rf -- \
    "${source_stage}/linux-wallpaperengine-${version}/.git" \
    "${source_stage}/linux-wallpaperengine-${version}/build" \
    "${source_stage}/linux-wallpaperengine-${version}/dist" \
    "${source_stage}/linux-wallpaperengine-${version}/output"
tar -czf "${rpm_topdir}/SOURCES/linux-wallpaperengine-${version}.tar.gz" \
    -C "${source_stage}" "linux-wallpaperengine-${version}"

rpmbuild \
    --define "_topdir ${rpm_topdir}" \
    --define "_rpmdir ${rpm_topdir}/RPMS" \
    -bb "${source_dir}/packaging/rpm/linux-wallpaperengine.spec"

mapfile -t rpms < <(find "${rpm_topdir}/RPMS" -type f -name '*.rpm' -print)
if [[ "${#rpms[@]}" -ne 1 ]]; then
    echo "error: expected one RPM, found ${#rpms[@]}" >&2
    exit 1
fi

install -m 0644 -- "${rpms[0]}" \
    "${artifact_dir}/linux-wallpaperengine-${version}-1.fc44.x86_64.rpm"
