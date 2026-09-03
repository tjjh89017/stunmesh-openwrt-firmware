# stunmesh-openwrt-firmware

Custom OpenWrt firmware images for STUNMESH devices, built with the OpenWrt
ImageBuilder and published as GitHub Releases.

## Disclaimer

```text
This project provides custom firmware images built with the
OpenWrt ImageBuilder.

OpenWrt is a registered trademark of Software Freedom
Conservancy.

This project is not affiliated with or endorsed by the
OpenWrt project.
```

## Install official OpenWrt first

```text
This project provides sysupgrade images only.

If the device does not run OpenWrt, install the official
OpenWrt firmware first.

Use the official OpenWrt installation instructions for
the device.

After OpenWrt is installed, use the matching sysupgrade
image from this project.
```

Official OpenWrt installation instructions: https://openwrt.org/docs/guide-quick-start/start

This project does not provide first-install, factory, initramfs, or recovery
images. OpenWrt upstream is responsible for the initial installation.

## Supported firmware targets

Select the exact firmware target that matches your device's flash layout.
The commercial device model alone is not enough — a physical model can map
to more than one firmware target.

| Firmware target       | Model      | Variant  | OpenWrt target/subtarget | OpenWrt profile              |
|------------------------|------------|----------|---------------------------|-------------------------------|
| `gl-ar750s-nor`        | GL-AR750S  | NOR      | ath79/nand                 | `glinet_gl-ar750s-nor`        |
| `gl-ar750s-nor-nand`   | GL-AR750S  | NOR+NAND | ath79/nand                 | `glinet_gl-ar750s-nor-nand`   |
| `gl-ar300m-nor`        | GL-AR300M  | NOR      | ath79/nand                 | `glinet_gl-ar300m-nor`        |
| `gl-ar300m-nand`       | GL-AR300M  | NAND     | ath79/nand                 | `glinet_gl-ar300m-nand`       |
| `gl-microuter-n300`    | GL.iNet microuter-N300 | Default | ramips/mt76x8   | `glinet_microuter-n300`       |
| `cudy-tr3000-v1`       | Cudy TR3000 v1 | Default  | mediatek/filogic          | `cudy_tr3000-v1`              |
| `gl-mt300n-v2`         | GL.iNet GL-MT300N v2 | Default | ramips/mt76x8       | `glinet_gl-mt300n-v2`         |

**Warning:** NOR and NOR+NAND (or NAND) images are different, incompatible
firmware targets, even on the same physical device model. Flashing the wrong
target's image is not a supported upgrade path. A normal sysupgrade must
stay on the same firmware target it started on.

## Build and CI overview

A daily (and push/manual-triggered) GitHub Actions workflow:

1. Finds the latest OpenWrt patch release in the configured series
   (`configs/openwrt.yaml`).
2. Downloads the matching ImageBuilder(s) and validates each configured
   profile.
3. Resolves the exact package set with `make manifest` for every firmware
   target.
4. Computes a build fingerprint from the OpenWrt version, project inputs,
   target/package configuration, and resolved manifests.
5. Builds firmware only when the fingerprint changed since the last release.
6. Publishes `*-sysupgrade.bin` images, `version.json`, `sha256sums`, and
   package manifests as assets on a new GitHub Release.

A documentation-only change or an unchanged fingerprint does not trigger a
new firmware build or Release.

## OpenWrt version selection

The OpenWrt series is pinned manually in `configs/openwrt.yaml`
(`series: "25.12"`). At CI time, `scripts/check-openwrt-version.sh` fetches
https://downloads.openwrt.org/releases/, matches only `25.12.N/` hrefs within
that series, and picks the highest with `sort -V` to resolve the latest patch
release.

The resolved version drives the ImageBuilder/feed URLs and enters the build
fingerprint, so a new upstream patch release is picked up automatically and
triggers a rebuild and new Release. Moving to a new series (e.g. `25.12` ->
`26.01`) means editing `configs/openwrt.yaml`.

## Releases

Each Release is tagged `firmware-{build_id}` and contains:

```text
version.json
sha256sums

stunmesh-openwrt-{openwrt_version}-{profile}-{build_id}-sysupgrade.bin
  (one per firmware target)

manifest-{firmware_target}.txt
  (one per firmware target)
```

`version.json` is the stable, current-release metadata file: it lists the
OpenWrt version, project packages, and per-firmware-target filename/sha256/size
so an updater can identify its exact firmware target and check for a newer
`build_id`. Old Releases are kept for rollback and troubleshooting.

## CI implementation

The workflow lives in `.github/workflows/firmware.yml` and is built from
composite actions in `.github/actions/`:

- `load-config` — parses `configs/` into the build matrix.
- `resolve-openwrt` — resolves the latest patch release.
- `setup-imagebuilder` — downloads, caches, and extracts the ImageBuilder,
  then configures the `stunmesh-openwrt` package feed.
- `fingerprint` — computes the project input hash and build fingerprint.
- `release-gate` — compares the fingerprint against the latest Release.

Jobs: `check` (gate) -> `build` (matrix, only when changed) -> `build-required`
(single required status check) -> `publish` (atomic Release, main only,
never on `pull_request`).

### Package feed

`setup-imagebuilder` adds the `stunmesh-openwrt` apk feed
(`https://tjjh89017.github.io/stunmesh-openwrt`) to the ImageBuilder's
`repositories` file and installs its signing key, so `configs/packages.txt`
can list the `stunmesh-agent` package directly (it embeds stunmesh-go,
so the image carries the one binary). That URL
is this action's default `feed_url` input. To point at a different feed
(a fork, a private mirror, or if the feed's publish location ever changes),
set the `STUNMESH_FEED_URL` repository variable
(Settings -> Secrets and variables -> Actions -> Variables) — the workflow
wires it in ahead of the built-in default.
