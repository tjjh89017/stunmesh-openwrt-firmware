#!/usr/bin/env bash
# Usage: setup.sh <openwrt_version> <target> <subtarget> <dest_dir> <feed_url> <series>
# Downloads/extracts the ImageBuilder and configures the feed; idempotent via <dest_dir>/.setup-complete.
set -euo pipefail

openwrt_version="${1:?openwrt_version is required}"
target="${2:?target is required}"
subtarget="${3:?subtarget is required}"
dest_dir="${4:?dest_dir is required}"
feed_url="${5:-}"
series="${6:?series is required}"

if [ -f "${dest_dir}/.setup-complete" ]; then
  printf '%s\n' "$dest_dir"
  exit 0
fi

base_url="https://downloads.openwrt.org/releases/${openwrt_version}/targets/${target}/${subtarget}"
name="openwrt-imagebuilder-${openwrt_version}-${target}-${subtarget}.Linux-x86_64"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

if curl -fsSL -o "${tmp_dir}/ib.tar.zst" "${base_url}/${name}.tar.zst"; then
  command -v zstd >/dev/null 2>&1 || { sudo apt-get update -qq && sudo apt-get install -y -qq zstd; }
  tar --zstd -xf "${tmp_dir}/ib.tar.zst" -C "$tmp_dir"
elif curl -fsSL -o "${tmp_dir}/ib.tar.xz" "${base_url}/${name}.tar.xz"; then
  tar -xJf "${tmp_dir}/ib.tar.xz" -C "$tmp_dir"
else
  echo "error: no ImageBuilder archive found for ${openwrt_version}/${target}/${subtarget}" >&2
  exit 1
fi

extracted_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d -name 'openwrt-imagebuilder-*')"
if [ -z "$extracted_dir" ]; then
  echo "error: ImageBuilder archive did not extract as expected" >&2
  exit 1
fi

mkdir -p "$(dirname "$dest_dir")"
rm -rf "$dest_dir"
mv "$extracted_dir" "$dest_dir"

if [ -n "$feed_url" ]; then
  if [ -f "${dest_dir}/repositories" ]; then
    # apk-based ImageBuilder (24.10+): "repositories" lists packages.adb URLs, one per line.
    arch="$(grep -oE '/packages/[^/]+/base/packages\.adb' "${dest_dir}/repositories" \
      | head -n1 | sed -E 's#/packages/([^/]+)/base/packages\.adb#\1#')"
    if [ -z "$arch" ]; then
      echo "error: could not determine package architecture from ${dest_dir}/repositories" >&2
      exit 1
    fi
    feed_line="${feed_url}/openwrt-${series}/${arch}/packages.adb"
    grep -qxF "$feed_line" "${dest_dir}/repositories" || echo "$feed_line" >> "${dest_dir}/repositories"
    mkdir -p "${dest_dir}/keys"
    curl -fsSL -o "${dest_dir}/keys/stunmesh.pem" "${feed_url}/stunmesh.pem"
  elif [ -f "${dest_dir}/repositories.conf" ]; then
    # opkg-based ImageBuilder (pre-24.10): feed is apk-only, cannot be added.
    echo "warning: opkg-based ImageBuilder detected; stunmesh-openwrt feed is apk-only, skipping" >&2
  fi
fi

touch "${dest_dir}/.setup-complete"
printf '%s\n' "$dest_dir"
