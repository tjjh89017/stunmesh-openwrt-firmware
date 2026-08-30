#!/usr/bin/env bash
# Usage: check-openwrt-version.sh <series>  (e.g. 25.12) -> prints latest patch e.g. 25.12.5
set -euo pipefail

series="${1:?series is required}"
base_url="https://downloads.openwrt.org/releases/"

listing="$(curl -fsSL "$base_url")"
series_re="$(printf '%s' "$series" | sed 's/[.[\*^$]/\\&/g')"
# match only full patch releases within the exact configured series, never cross series
latest="$(printf '%s\n' "$listing" \
  | grep -oE "href=\"${series_re}\.[0-9]+/\"" \
  | sed -E 's/href="([^"]+)\/"/\1/' \
  | sort -V \
  | tail -n1)"

if [ -z "$latest" ]; then
  echo "error: no patch release found for series ${series}" >&2
  exit 1
fi

printf '%s\n' "$latest"
