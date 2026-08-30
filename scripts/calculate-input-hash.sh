#!/usr/bin/env bash
# Usage: calculate-input-hash.sh <repo_root> -> prints SHA256 project input hash
# Hashes configs/**, files/**, scripts/**, .github/workflows/firmware.yml (paths-ignore per spec §20).
set -euo pipefail

repo_root="${1:?repo_root is required}"
cd "$repo_root"

file_list=""
for d in configs files scripts; do
  if [ -d "$d" ]; then
    file_list="${file_list}$(find "$d" -type f | sort)"$'\n'
  fi
done
if [ -f .github/workflows/firmware.yml ]; then
  file_list="${file_list}.github/workflows/firmware.yml"$'\n'
fi

sorted_files="$(printf '%s' "$file_list" | grep -v '^$' | sort)"

combined=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  content_hash="$(sha256sum "$f" | awk '{print $1}')"
  combined="${combined}${f}:${content_hash}"$'\n'
done <<< "$sorted_files"

printf '%s' "$combined" | sha256sum | awk '{print $1}'
