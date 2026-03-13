# Busybox Image Builder
Build Docker images with a specified subset of busybox applets easily.
The project allows to build very small images under 100KB.

## Build args
- `VERSION_BUSYBOX` (1.37.0) - busybox version to build
- `ARCH` (**x86-64-v2**, x86-i686, [...](https://toolchains.bootlin.com/toolchains.html)) - CPU architecture
- `CLIB` (uclibc, **musl**, glibc) - C library
- `VERSION_TOOLCHAIN` (bleeding-edge-2025.08-1) - Bootlin toolchain version
- `APPLETS` - space separated busybox utilities to include

## Build tool script
`.\build-tool.ps1` changes entrypoint from `/bin/busybox` to the first item in `--build-arg APPLETS=...`.

## See also
- [PrivateBin/docker-chown](https://github.com/PrivateBin/docker-chown)
- [Qwer-TeX/minibox](https://github.com/Qwer-TeX/minibox)
- [Bootlin toolchains](https://toolchains.bootlin.com)
