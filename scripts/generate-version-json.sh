#!/usr/bin/env bash
# Usage: generate-version-json.sh <output_file> <build_id> <timestamp> <build_fingerprint> <openwrt_version> <packages_json> <target_fragment_json...>
# Each target_fragment_json is {"id":..., "model":..., "variant":..., "target":..., "subtarget":..., "profile":..., "filename":..., "sha256":..., "size":...}
# Assembles version.json (spec §30). Uses python3 for reliable JSON merging.
set -euo pipefail

if [ "$#" -lt 6 ]; then
  echo "usage: generate-version-json.sh <output_file> <build_id> <timestamp> <build_fingerprint> <openwrt_version> <packages_json> <target_fragment_json...>" >&2
  exit 1
fi

output_file="$1"
build_id="$2"
timestamp="$3"
build_fingerprint="$4"
openwrt_version="$5"
packages_json="$6"
shift 6

mkdir -p "$(dirname "$output_file")"

python3 - "$output_file" "$build_id" "$timestamp" "$build_fingerprint" "$openwrt_version" "$packages_json" "$@" <<'PYEOF'
import json, sys

output_file, build_id, timestamp, build_fingerprint, openwrt_version, packages_json = sys.argv[1:7]
fragments = sys.argv[7:]

version = {
    "build_id": build_id,
    "timestamp": timestamp,
    "build_fingerprint": build_fingerprint,
    "base_distribution": "OpenWrt",
    "openwrt_version": openwrt_version,
    "packages": json.loads(packages_json),
    "firmware_targets": {},
}

for frag in fragments:
    data = json.loads(frag)
    target_id = data.pop("id")
    version["firmware_targets"][target_id] = data

with open(output_file, "w") as f:
    json.dump(version, f, indent=2)
    f.write("\n")
PYEOF

printf '%s\n' "$output_file"
