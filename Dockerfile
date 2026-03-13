ARG VERSION_BUSYBOX="1.37.0"

FROM debian:13-slim AS builder
# host gcc is used for building utilities during cross-compilation process
RUN apt-get update && apt-get install -y curl xz-utils bzip2 make gcc

WORKDIR /build
ARG VERSION_BUSYBOX
# bootlin toolchain (glibc, musl, uclibc)
ARG ARCH="x86-64-v2"
ARG CLIB="musl"
ARG VERSION_TOOLCHAIN="bleeding-edge-2025.08-1"

RUN curl -L https://toolchains.bootlin.com/downloads/releases/toolchains/$ARCH/tarballs/$ARCH--$CLIB--$VERSION_TOOLCHAIN.tar.xz | tar -xJ
ENV PATH="/build/$ARCH--$CLIB--$VERSION_TOOLCHAIN/bin:$PATH"

RUN curl -L https://busybox.net/downloads/busybox-$VERSION_BUSYBOX.tar.bz2 | tar -xj
WORKDIR /build/busybox-$VERSION_BUSYBOX

RUN make allnoconfig

RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config && \
    sed -i 's/# CONFIG_LFS is not set/CONFIG_LFS=y/' .config && \
    sed -i 's/# CONFIG_BUSYBOX is not set/CONFIG_BUSYBOX=y/' .config && \
    sed -i 's/CONFIG_SH_IS_ASH=y/# CONFIG_SH_IS_ASH is not set/' .config && \
    sed -i 's/# CONFIG_SH_IS_NONE is not set/CONFIG_SH_IS_NONE=y/' .config && \
    # Navigation (history, tab completion)
    sed -i 's/# CONFIG_FEATURE_EDITING is not set/CONFIG_FEATURE_EDITING=y/' .config && \
    sed -i 's/CONFIG_FEATURE_EDITING_MAX_LEN=0/CONFIG_FEATURE_EDITING_MAX_LEN=1024/' .config && \
    sed -i 's/CONFIG_FEATURE_EDITING_HISTORY=0/CONFIG_FEATURE_EDITING_HISTORY=150/' .config && \
    sed -i 's/# CONFIG_FEATURE_TAB_COMPLETION is not set/CONFIG_FEATURE_TAB_COMPLETION=y/' .config

ARG APPLETS
RUN for applet in $(echo "$APPLETS" | tr '[:lower:]' '[:upper:]'); do \
        sed -i "s/# CONFIG_$applet is not set/CONFIG_$applet=y/" .config || true; \
        if [ "$applet" = "HUSH" ]; then \
            sed -i 's/CONFIG_SH_IS_ASH=y/# CONFIG_SH_IS_ASH is not set/' .config && \
            sed -i 's/# CONFIG_SH_IS_HUSH is not set/CONFIG_SH_IS_HUSH=y/' .config; \
            sed -i 's/CONFIG_SH_IS_NONE=y/# CONFIG_SH_IS_NONE is not set/' .config && \
            sed -i 's/# CONFIG_FEATURE_SH_STANDALONE is not set/CONFIG_FEATURE_SH_STANDALONE=y/' .config; \
            sed -i 's/# CONFIG_HUSH_INTERACTIVE is not set/CONFIG_HUSH_INTERACTIVE=y/' .config; \
            sed -i 's/# CONFIG_HUSH_JOB is not set/CONFIG_HUSH_JOB=y/' .config; \
        elif [ "$applet" = "ASH" ]; then \
            sed -i 's/# CONFIG_SH_IS_ASH is not set/CONFIG_SH_IS_ASH=y/' .config; \
            sed -i 's/CONFIG_SH_IS_HUSH=y/# CONFIG_SH_IS_HUSH is not set/' .config && \
            sed -i 's/CONFIG_SH_IS_NONE=y/# CONFIG_SH_IS_NONE is not set/' .config && \
            sed -i 's/# CONFIG_FEATURE_SH_STANDALONE is not set/CONFIG_FEATURE_SH_STANDALONE=y/' .config; \
        fi \
    done

RUN export CROSS_COMPILE="$(basename /build/$ARCH--$CLIB--$VERSION_TOOLCHAIN/*-buildroot-linux-*)-" && \
    make -j$(nproc) && \
    make CONFIG_PREFIX=/build/rootfs install

# FROM backplane/upx:latest AS upx
# ARG VERSION_BUSYBOX
# COPY --from=builder /build/busybox-$VERSION_BUSYBOX/busybox /build/busybox-$VERSION_BUSYBOX/busybox
# RUN upx --brute /build/busybox-$VERSION_BUSYBOX/busybox

FROM scratch
COPY --from=builder /build/rootfs /
ENTRYPOINT ["/bin/sh"]
