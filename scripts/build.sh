#!/usr/bin/env bash
# Usage: build.sh <imagebuilder_dir> <profile> <packages_file> <files_overlay_dir> <openwrt_version> <build_id> <output_dir>
# Runs make image, finds the *-sysupgrade.bin, copies it as
# stunmesh-openwrt-<openwrt_version>-<profile>-<build_id>-sysupgrade.bin, prints the resulting path.
set -euo pipefail

ib_dir="${1:?imagebuilder_dir is required}"
profile="${2:?profile is required}"
packages_file="${3:?packages_file is required}"
files_dir="${4:?files_overlay_dir is required}"
openwrt_version="${5:?openwrt_version is required}"
build_id="${6:?build_id is required}"
output_dir="${7:?output_dir is required}"

packages="$(grep -vE '^\s*(#|$)' "$packages_file" | tr '\n' ' ' | sed -E 's/[[:space:]]+$//')"
files_abs="$(cd "$files_dir" && pwd)"

# ib_dir is cached and keyed only by openwrt_version/target/subtarget (see
# .github/actions/setup-imagebuilder/action.yml), so two firmware targets
# that share a target/subtarget (e.g. ramips/mt76x8) share the same cached
# ImageBuilder directory. `make image` never cleans bin/targets/ of a
# previous run's output, so a stale *-sysupgrade.bin from an older build of
# a *different* profile can survive in the cache indefinitely. Wipe bin/
# first so the find below can only ever see this build's own output.
rm -rf "${ib_dir:?}/bin"

# redirect to stderr: callers capture this script's stdout as the image path
make --no-print-directory -C "$ib_dir" image PROFILE="$profile" PACKAGES="$packages" FILES="$files_abs" >&2

mapfile -t candidates < <(find "$ib_dir/bin" -type f -name '*-sysupgrade.bin')
if [ "${#candidates[@]}" -eq 0 ]; then
  echo "error: no *-sysupgrade.bin produced by make image" >&2
  exit 1
fi
if [ "${#candidates[@]}" -gt 1 ]; then
  echo "error: expected exactly one *-sysupgrade.bin for profile '${profile}', got ${#candidates[@]}:" >&2
  printf '  %s\n' "${candidates[@]}" >&2
  exit 1
fi
src="${candidates[0]}"

# Regression guard: the built file must actually belong to the requested
# profile, not a leftover from a different profile sharing this ib_dir.
case "$(basename "$src")" in
*"$profile"*) ;;
*)
  echo "error: built image '$(basename "$src")' does not match requested profile '${profile}'" >&2
  exit 1
  ;;
esac

mkdir -p "$output_dir"
dest="${output_dir}/stunmesh-openwrt-${openwrt_version}-${profile}-${build_id}-sysupgrade.bin"
cp "$src" "$dest"

printf '%s\n' "$dest"
