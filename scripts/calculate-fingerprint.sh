#!/usr/bin/env bash
# Usage: calculate-fingerprint.sh <openwrt_version> <input_hash> <firmware_targets_yaml> <packages_txt> <feed_url> <manifest...>
# Prints the SHA256 build_fingerprint combining all build-relevant inputs (spec §21).
set -euo pipefail

if [ "$#" -lt 6 ]; then
  echo "usage: calculate-fingerprint.sh <openwrt_version> <input_hash> <firmware_targets_yaml> <packages_txt> <feed_url> <manifest...>" >&2
  exit 1
fi

openwrt_version="$1"
input_hash="$2"
targets_file="$3"
packages_file="$4"
feed_url="$5"
shift 5
manifests=("$@")

targets_hash="$(sha256sum "$targets_file" | awk '{print $1}')"
packages_hash="$(sha256sum "$packages_file" | awk '{print $1}')"

combined="openwrt_version:${openwrt_version}"$'\n'
combined="${combined}input_hash:${input_hash}"$'\n'
combined="${combined}firmware_targets:${targets_hash}"$'\n'
combined="${combined}packages:${packages_hash}"$'\n'
combined="${combined}feed_url:${feed_url}"$'\n'

for m in "${manifests[@]}"; do
  m_hash="$(sha256sum "$m" | awk '{print $1}')"
  combined="${combined}manifest:${m}:${m_hash}"$'\n'
done

printf '%s' "$combined" | sha256sum | awk '{print $1}'
