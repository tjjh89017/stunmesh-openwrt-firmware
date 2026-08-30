#!/usr/bin/env bash
# Usage: verify-image.sh <image_file> -> checks existence and non-empty, prints "<sha256>  <path>" (spec §36)
set -euo pipefail

image_file="${1:?image_file is required}"

if [ ! -f "$image_file" ]; then
  echo "error: image file not found: ${image_file}" >&2
  exit 1
fi

size="$(stat -c%s "$image_file" 2>/dev/null || stat -f%z "$image_file")"
if [ "$size" -eq 0 ]; then
  echo "error: image file is empty: ${image_file}" >&2
  exit 1
fi

sha256sum "$image_file"
