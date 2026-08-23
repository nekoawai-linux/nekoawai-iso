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
# One version for the whole distribution: nekoawai-linux/nekoawai.conf owns it
# (NEKO_VERSION), the same value the packages are built with. config.xml keeps a
# placeholder that is stamped over in the staged copy below.
. "$linux_root/nekoawai.conf"
version=$NEKO_VERSION
final=$root/out/nekoawai-online-cli-$version-x86_64.iso

"$root/scripts/check.sh"

rm -rf "$stage" "$result"
mkdir -p \
	"$stage/repositories/target" \
	"$stage/repositories/installer" \
	"$stage/root/usr/share/nekoawai/repo" \
	"$result"
install -m 0644 "$root/config.xml" "$stage/config.xml"
# Stamp the single-sourced distribution version into the staged recipe.
sed -i "s|<version>[^<]*</version>|<version>$version</version>|" "$stage/config.xml"
# KIWI's signature check is one switch for the whole description, not one per
# repository, so it can only go on once everything in it is signed. The moment
# the target repository arrives with a signature over its metadata the staged
# description asks for the check, and the file in the repository goes on
# saying what is true today. See nekoawai-linux, NEKO_SIGN_KEY.
if [ -f "$target_repo/repodata/repomd.xml.asc" ]; then
	sed -i 's|<rpm-check-signatures>false<|<rpm-check-signatures>true<|' "$stage/config.xml"
	echo "target repository is signed: building with rpm-check-signatures"
fi
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
