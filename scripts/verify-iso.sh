#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's|.*<version>\(.*\)</version>.*|\1|p' "$root/config.xml")
iso=${1:-$root/out/nekoawai-online-cli-$version-x86_64.iso}

[ -f "$iso" ] || { echo "ISO not found: $iso" >&2; exit 1; }

report=$(xorriso -indev "$iso" -report_el_torito plain 2>&1)
grep -qi 'UEFI' <<< "$report" || { echo "UEFI boot entry not found" >&2; exit 1; }
# The absence is the thing being checked. nekoawai-install is UEFI-only, so a
# legacy BIOS entry does nothing but carry somebody to a refusal.
if grep -qi 'BIOS' <<< "$report"; then
	echo "Legacy BIOS boot entry found: this image is meant to be EFI only" >&2
	exit 1
fi

xorriso -osirrox on -indev "$iso" -find /boot -type f -exec lsdl -- 2>/dev/null |
	grep -q '/boot/.*/loader/linux' || { echo "Live kernel not found in ISO" >&2; exit 1; }

echo "UEFI-only ISO verified: $iso"
