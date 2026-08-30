#!/usr/bin/env bash
# Usage: build.sh <imagebuilder_dir> <profile> <packages_file> <files_overlay_dir> <firmware_target> <openwrt_version> <build_id> <output_dir>
# Runs make image, finds the *-sysupgrade.bin, copies it under the spec §25 naming scheme, prints the resulting path.
set -euo pipefail

ib_dir="${1:?imagebuilder_dir is required}"
profile="${2:?profile is required}"
packages_file="${3:?packages_file is required}"
files_dir="${4:?files_overlay_dir is required}"
firmware_target="${5:?firmware_target is required}"
openwrt_version="${6:?openwrt_version is required}"
build_id="${7:?build_id is required}"
output_dir="${8:?output_dir is required}"

packages="$(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ' | sed -E 's/[[:space:]]+$//')"
files_abs="$(cd "$files_dir" && pwd)"

make -C "$ib_dir" image PROFILE="$profile" PACKAGES="$packages" FILES="$files_abs"

src="$(find "$ib_dir/bin" -type f -name '*-sysupgrade.bin' | head -n1)"
if [ -z "$src" ]; then
  echo "error: no *-sysupgrade.bin produced by make image" >&2
  exit 1
fi

mkdir -p "$output_dir"
dest="${output_dir}/stunmesh-openwrt-${firmware_target}-${openwrt_version}-${build_id}-sysupgrade.bin"
cp "$src" "$dest"

printf '%s\n' "$dest"
