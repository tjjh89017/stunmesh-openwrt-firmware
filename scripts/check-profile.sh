#!/usr/bin/env bash
# Usage: check-profile.sh <imagebuilder_dir> <profile> -> exits non-zero if profile is missing
set -euo pipefail

ib_dir="${1:?imagebuilder_dir is required}"
profile="${2:?profile is required}"

info_output="$(make --no-print-directory -C "$ib_dir" info)"

if ! grep -qE "^${profile}:" <<<"$info_output"; then
  echo "error: profile '${profile}' not found in ${ib_dir}" >&2
  exit 1
fi

echo "profile '${profile}' found"
