# Busybox Image Builder
Build Docker images with specified busybox utilities with ease.

## Build args
- `VERSION_BUSYBOX` (1.37.0) - busybox version to build
- `ARCH` (**x86-64**, x86-i686, [...](https://toolchains.bootlin.com/toolchains.html)) - CPU architecture
- `VARIANT`("", **-v2**, -v3, -v4, -core-i7) - x86-64 architecture level
- `CLIB` (uclibc, **musl**, glibc) - C library
- `VERSION_TOOLCHAIN` (bleeding-edge-2025.08-1) - Bootlin toolchain version
- `UTILS` - space separated busybox utilities to include (hush shell is always included)

## Build tool script
`.\build-tool.ps1` changes entrypoint to the first item in `--build-arg UTILS=...`.

## See also
- [PrivateBin/docker-chown](https://github.com/PrivateBin/docker-chown)
- [Qwer-TeX/minibox](https://github.com/Qwer-TeX/minibox)
- [Bootlin toolchains](https://toolchains.bootlin.com)
