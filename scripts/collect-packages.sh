#!/usr/bin/env bash
# Usage: collect-packages.sh <manifest_file> <packages_txt> -> prints JSON {"pkg":"version",...} for the project package list, skipping "-<name>" exclude lines
set -euo pipefail

manifest_file="${1:?manifest_file is required}"
packages_file="${2:?packages_txt is required}"

# first pass: collect excluded package names from "-<name>" lines
excludes=""
while IFS= read -r pkg; do
  case "$pkg" in
    -*) excludes="${excludes} ${pkg#-}" ;;
  esac
done < "$packages_file"

json="{"
first=1
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  case "$pkg" in \#*) continue ;; esac
  case "$pkg" in -*) continue ;; esac
  case " ${excludes} " in *" ${pkg} "*) continue ;; esac
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
