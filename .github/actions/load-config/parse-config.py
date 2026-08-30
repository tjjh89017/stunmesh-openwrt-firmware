#!/usr/bin/env python3
# Parses configs/firmware-targets.yaml and configs/openwrt.yaml without a YAML
# library, since both files use a fixed flat "key: value" structure only.
# Prints matrix/ib_pairs/series as GITHUB_OUTPUT lines.
import json
import sys


def parse_flat_list(path, list_key):
    items = []
    current = None
    with open(path) as f:
        for raw in f:
            stripped = raw.strip()
            if not stripped or stripped.startswith("#") or stripped == f"{list_key}:":
                continue
            if stripped.startswith("- "):
                if current is not None:
                    items.append(current)
                current = {}
                stripped = stripped[2:].strip()
            if current is None:
                continue
            if ":" in stripped:
                key, value = stripped.split(":", 1)
                current[key.strip()] = value.strip().strip('"').strip("'")
    if current is not None:
        items.append(current)
    return items


def parse_scalar(path, key):
    with open(path) as f:
        for raw in f:
            stripped = raw.strip()
            if stripped.startswith(f"{key}:"):
                return stripped.split(":", 1)[1].strip().strip('"').strip("'")
    raise ValueError(f"key '{key}' not found in {path}")


targets_file, openwrt_file = sys.argv[1], sys.argv[2]

targets = parse_flat_list(targets_file, "firmware_targets")
series = parse_scalar(openwrt_file, "series")

pairs = sorted({(t["target"], t["subtarget"]) for t in targets})
ib_pairs = [{"target": t, "subtarget": s} for t, s in pairs]

print(f"matrix={json.dumps({'include': targets})}")
print(f"ib_pairs={json.dumps(ib_pairs)}")
print(f"series={series}")
