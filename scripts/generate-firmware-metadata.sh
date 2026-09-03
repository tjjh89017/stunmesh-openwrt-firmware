#!/usr/bin/env bash
# Usage: generate-firmware-metadata.sh <output_file> <build_id> <timestamp> <openwrt_version> \
#        <firmware_target> <model> <variant> <target> <subtarget> <profile> <packages_json>
# Writes /etc/firmware-build.json content (spec §29) to output_file.
set -euo pipefail

if [ "$#" -ne 11 ]; then
  echo "usage: generate-firmware-metadata.sh <output_file> <build_id> <timestamp> <openwrt_version> <firmware_target> <model> <variant> <target> <subtarget> <profile> <packages_json>" >&2
  exit 1
fi

output_file="$1"
build_id="$2"
timestamp="$3"
openwrt_version="$4"
firmware_target="$5"
model="$6"
variant="$7"
target="$8"
subtarget="$9"
profile="${10}"
packages_json="${11}"

mkdir -p "$(dirname "$output_file")"

cat > "$output_file" <<EOF
{
  "build_id": "${build_id}",
  "timestamp": "${timestamp}",
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
