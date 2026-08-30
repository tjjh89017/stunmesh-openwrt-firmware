#!/usr/bin/env bash
# Usage: get-manifest.sh <imagebuilder_dir> <profile> <packages_file> [output_file]
# Prints resolved manifest to stdout, or writes it to output_file if given.
set -euo pipefail

ib_dir="${1:?imagebuilder_dir is required}"
profile="${2:?profile is required}"
packages_file="${3:?packages_file is required}"
output_file="${4:-}"

packages="$(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ' | sed -E 's/[[:space:]]+$//')"

manifest="$(make --no-print-directory -C "$ib_dir" manifest PROFILE="$profile" PACKAGES="$packages")"

if [ -n "$output_file" ]; then
  printf '%s\n' "$manifest" > "$output_file"
else
  printf '%s\n' "$manifest"
fi
