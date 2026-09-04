#!/usr/bin/env bash
# Usage: prepare-packages.sh <packages_txt> <extra_packages> <output_file> <exclude_packages>
# Writes packages_txt plus extra_packages (a space-separated list, may be
# empty) as one-per-line to output_file. Lets a firmware target pull in
# packages that only exist on its OpenWrt target/subtarget,
# without adding them to the shared configs/packages.txt list.
# exclude_packages (a space-separated list, may be empty) is written as
# "-<name>" per line, so ImageBuilder drops it from the shared list on
# targets/subtargets where it does not exist.
set -euo pipefail

packages_file="${1:?packages_txt is required}"
extra_packages="${2:-}"
output_file="${3:?output_file is required}"
exclude_packages="${4:-}"

cp "$packages_file" "$output_file"

for pkg in $extra_packages; do
  printf '%s\n' "$pkg" >> "$output_file"
done

for pkg in $exclude_packages; do
  printf -- '-%s\n' "$pkg" >> "$output_file"
done
