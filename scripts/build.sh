#!/bin/bash

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "build requires root" >&2; exit 1; }

root=$(cd "$(dirname "$0")/.." && pwd)
config=$root/config/build.conf
[ ! -f "$config" ] || . "$config"

linux_root=${NEKO_LINUX_ROOT:-$root/../nekoawai-linux}
target_repo=${NEKO_TARGET_REPO:-$linux_root/out/repo}
installer_repo=${NEKO_INSTALLER_REPO:-$linux_root/out/installer-repo}
stage=$root/out/description
result=$root/out/result
# The recipe owns the version, so the name of the image cannot drift from it.
version=$(sed -n 's|.*<version>\(.*\)</version>.*|\1|p' "$root/config.xml")
final=$root/out/nekoawai-online-cli-$version-x86_64.iso

"$root/scripts/check.sh"

rm -rf "$stage" "$result"
mkdir -p \
	"$stage/repositories/target" \
	"$stage/repositories/installer" \
	"$stage/root/usr/share/nekoawai/repo" \
	"$result"
install -m 0644 "$root/config.xml" "$stage/config.xml"
install -m 0755 "$root/config.sh" "$stage/config.sh"
cp -a "$root/root"/. "$stage/root"/
cp -a "$target_repo"/. "$stage/root/usr/share/nekoawai/repo"/
cp -a "$target_repo"/. "$stage/repositories/target"/
cp -a "$installer_repo"/. "$stage/repositories/installer"/

kiwi-ng system build \
	--description "$stage" \
	--target-dir "$result"

images=("$result"/*.iso)
[ -e "${images[0]}" ] && [ "${#images[@]}" -eq 1 ] || {
	echo "KIWI did not produce exactly one ISO in $result" >&2
	exit 1
}
install -m 0644 "${images[0]}" "$final"
echo "ISO: $final"
