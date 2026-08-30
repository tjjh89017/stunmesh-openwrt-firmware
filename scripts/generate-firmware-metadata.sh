#!/usr/bin/env bash
# Usage: generate-firmware-metadata.sh <output_file> <build_id> <timestamp> <build_fingerprint> <openwrt_version> \
#        <firmware_target> <model> <variant> <target> <subtarget> <profile> <packages_json>
# Writes /etc/firmware-build.json content (spec §29) to output_file.
set -euo pipefail

if [ "$#" -ne 12 ]; then
  echo "usage: generate-firmware-metadata.sh <output_file> <build_id> <timestamp> <build_fingerprint> <openwrt_version> <firmware_target> <model> <variant> <target> <subtarget> <profile> <packages_json>" >&2
  exit 1
fi

output_file="$1"
build_id="$2"
timestamp="$3"
build_fingerprint="$4"
openwrt_version="$5"
firmware_target="$6"
model="$7"
variant="$8"
target="$9"
subtarget="${10}"
profile="${11}"
packages_json="${12}"

mkdir -p "$(dirname "$output_file")"

cat > "$output_file" <<EOF
{
  "build_id": "${build_id}",
  "timestamp": "${timestamp}",
  "build_fingerprint": "${build_fingerprint}",
  "base_distribution": "OpenWrt",
  "openwrt_version": "${openwrt_version}",
  "firmware_target": "${firmware_target}",
  "model": "${model}",
  "variant": "${variant}",
  "target": "${target}",
  "subtarget": "${subtarget}",
  "profile": "${profile}",
  "packages": ${packages_json}
}
EOF

printf '%s\n' "$output_file"
