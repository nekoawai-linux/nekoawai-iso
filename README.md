<div align="center">

# nekoawai-iso

![Release](https://img.shields.io/github/v/release/nekoawai-linux/nekoawai-iso?include_prereleases&label=ISO%20Release&style=for-the-badge)
![Stars](https://img.shields.io/github/stars/nekoawai-linux/nekoawai-iso?style=for-the-badge&color=%23daaa3f)
![License](https://img.shields.io/github/license/nekoawai-linux/nekoawai-iso?color=green&style=for-the-badge)
[![Website](https://img.shields.io/badge/Website-nekoawai.moe-%23e32b6b?style=for-the-badge)](https://nekoawai.moe)

**The recipe for the bootable [NekoAwai](https://github.com/nekoawai-linux/nekoawai-linux) Live image.**

</div>

## What it builds

`nekoawai-online-cli-0.0.1-x86_64.iso`, a hybrid UEFI and Legacy BIOS image
that boots to a text login and carries the installer. The NekoAwai packages
are embedded; the kernel, the desktops and everything else upstream are
downloaded from openSUSE Tumbleweed during installation, which is why the
image is called online.

## Build

Build the NekoAwai RPM repositories first:

    make -C ../nekoawai-linux

Then validate the inputs, build, and check the result:

    make check
    make build
    make verify

KIWI NG and `kiwi-systemdeps-iso-media` are required on the build host, and
`make build` needs root. Generated roots, repository caches and images stay
below `out/`, which is never committed.

## Live behaviour

The image boots to a normal tty login. Sign in as `root` with the password
`kawaii`, then run `nekoawai-install`.

The welcome, the public credentials, the `/run/nekoawai/live` marker and the
embedded target repository belong to this image alone. None of them is copied
into the installed system, and `nekofetch` is never started automatically.

## Layout

    config.xml          the KIWI image: packages, users, boot layout
    config.sh           final service state inside the prepared Live root
    root/               files copied only into the Live filesystem
    scripts/            input validation, the KIWI run, ISO verification

## Contributing

This repository owns the Live image and Live-only files. Distribution RPMs
belong to
[nekoawai-linux](https://github.com/nekoawai-linux/nekoawai-linux), the
installer to
[nekoawai-installer](https://github.com/nekoawai-linux/nekoawai-installer).
Do not move installed-system policy into the image recipe.

Keep the embedded target repository free of the installer: it is installed in
the Live root and must not reach the target. Live-only behaviour is guarded by
`/run/nekoawai/live`.

Text in `root/` is ASCII only, because the Live console has the built-in font
and nothing else. Run `make check` before `make build`, and `make verify` on
every image produced.

## License

Copyright (c) 2026 shizukiq. GPL-3.0-or-later; see `LICENSE`.
