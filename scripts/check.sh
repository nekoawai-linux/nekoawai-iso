#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
config=$root/config/build.conf
[ ! -f "$config" ] || . "$config"

linux_root=${NEKO_LINUX_ROOT:-$root/../nekoawai-linux}
target_repo=${NEKO_TARGET_REPO:-$linux_root/out/repo}
installer_repo=${NEKO_INSTALLER_REPO:-$linux_root/out/installer-repo}

for command in kiwi-ng rpm xorriso; do
	command -v "$command" >/dev/null || { echo "missing build command: $command" >&2; exit 1; }
done
[ -f "$target_repo/repodata/repomd.xml" ] || { echo "target repository not built: $target_repo" >&2; exit 1; }
[ -f "$installer_repo/repodata/repomd.xml" ] || { echo "installer repository not built: $installer_repo" >&2; exit 1; }

installer_rpms=("$installer_repo"/nekoawai-install-*.rpm)
[ -e "${installer_rpms[0]}" ] && [ "${#installer_rpms[@]}" -eq 1 ] || {
	echo "expected exactly one installer RPM in $installer_repo" >&2
	exit 1
}

for rpm_file in "$target_repo"/*.rpm; do
	[ -e "$rpm_file" ] || continue
	case $(rpm -qp --queryformat '%{NAME}' "$rpm_file") in
	nekoawai-install | nekoawai-installer)
		echo "Live-only installer found in target repository: $rpm_file" >&2
		exit 1
		;;
	esac
done

grep -q 'Welcome to NekoAwai Live' "$root/root/usr/lib/issue.d/50-nekoawai-live.issue"
grep -q 'nekoawai-install' "$root/root/usr/lib/issue.d/50-nekoawai-live.issue"
grep -qx 'nekoawai' "$root/root/etc/hostname"
# The Live console has the built-in font and nothing else: text outside ASCII
# reaches the screen as garbage.
if LC_ALL=C grep -rn '[^[:print:][:space:]]' "$root/root"; then
	echo "Live overlay text must stay ASCII" >&2
	exit 1
fi
if rg -q 'nekofetch' "$root/config.xml" "$root/config.sh" "$root/root"; then
	echo "nekofetch must not be started or configured by the Live image" >&2
	exit 1
fi

bash -n "$root/config.sh" "$root"/scripts/*.sh
if command -v shellcheck >/dev/null; then
	# SC1090 is config/build.conf, read at run time and optional. Warnings
	# and above only: the info level is style advice, and no two machines
	# here carry the same shellcheck.
	shellcheck --shell=bash --severity=warning --exclude=SC1090 "$root/config.sh" "$root"/scripts/*.sh
else
	echo "shellcheck is not installed here; CI runs it"
fi

# The image is EFI only, because nekoawai-install is. A BIOS boot entry would
# only carry somebody to a machine the installer refuses to work on.
# Matched as attributes and elements rather than as words, so that the comment
# in config.xml can name what was removed without tripping its own check.
if grep -q 'gpt_hybrid_mbr=\|<package name="grub2-i386-pc"' "$root/config.xml"; then
	echo "the image description asks for legacy BIOS boot; the installer is UEFI only" >&2
	exit 1
fi
if ! grep -q 'eficsm="false"' "$root/config.xml"; then
	echo "eficsm is not disabled; KIWI writes a BIOS boot entry without it" >&2
	exit 1
fi

# patternType="onlyRequired" drops every recommendation, and the base pattern
# only recommends the firmware. The medium has to name it outright or it boots
# in a virtual machine and on no real network card at all.
if ! grep -q 'kernel-firmware-all' "$root/config.xml"; then
	echo "the image description does not name kernel-firmware-all" >&2
	exit 1
fi
mkdir -p "$root/out/tmp"
kiwi-ng --temp-dir "$root/out/tmp" image info --description "$root" >/dev/null

echo "NekoAwai Online CLI ISO inputs are valid"
