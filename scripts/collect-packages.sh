#!/usr/bin/env bash
# Usage: collect-packages.sh <manifest_file> <packages_txt> -> prints JSON {"pkg":"version",...} for the project package list
set -euo pipefail

manifest_file="${1:?manifest_file is required}"
packages_file="${2:?packages_txt is required}"

json="{"
first=1
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in \#*) continue ;; esac
  # manifest lines look like "pkgname - version"
  version="$(grep -E "^${pkg} - " "$manifest_file" | head -n1 | sed -E "s/^${pkg} - //")"
  if [ -z "$version" ]; then
    echo "error: package '${pkg}' not found in manifest" >&2
    exit 1
  fi
  if [ "$first" -eq 0 ]; then json="${json},"; fi
  json="${json}\"${pkg}\":\"${version}\""
  first=0
done < "$packages_file"
json="${json}}"

printf '%s\n' "$json"
