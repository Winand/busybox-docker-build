ARG VERSION_BUSYBOX="1.37.0"

FROM debian:13-slim AS builder
# host gcc is used for building utilities during cross-compilation process
RUN apt-get update && apt-get install -y curl xz-utils bzip2 make gcc

WORKDIR /build
ARG VERSION_BUSYBOX
# bootlin toolchain (glibc, musl, uclibc)
ARG ARCH="x86-64"
ARG VARIANT="-v2"
ARG CLIB="musl"
ARG VERSION_TOOLCHAIN="bleeding-edge-2025.08-1"

RUN curl -L https://toolchains.bootlin.com/downloads/releases/toolchains/$ARCH$VARIANT/tarballs/$ARCH$VARIANT--$CLIB--$VERSION_TOOLCHAIN.tar.xz | tar -xJ
ENV PATH="/build/$ARCH$VARIANT--$CLIB--$VERSION_TOOLCHAIN/bin:$PATH"
ENV CROSS_COMPILE="${ARCH/-/_}-buildroot-linux-${CLIB/glibc/gnu}-"

RUN curl -L https://busybox.net/downloads/busybox-$VERSION_BUSYBOX.tar.bz2 | tar -xj
WORKDIR /build/busybox-$VERSION_BUSYBOX

RUN make allnoconfig

# Critical for 'FROM scratch'
RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config && \
    sed -i 's/# CONFIG_BUSYBOX is not set/CONFIG_BUSYBOX=y/' .config && \
    sed -i 's/# CONFIG_FEATURE_INSTALLER is not set/CONFIG_FEATURE_INSTALLER=y/' .config && \
    # hush shell configuration
    sed -i 's/# CONFIG_HUSH is not set/CONFIG_HUSH=y/' .config && \
    sed -i 's/CONFIG_SH_IS_ASH=y/# CONFIG_SH_IS_ASH is not set/' .config && \
    sed -i 's/# CONFIG_SH_IS_HUSH is not set/CONFIG_SH_IS_HUSH=y/' .config && \
    sed -i 's/# CONFIG_HUSH_INTERACTIVE is not set/CONFIG_HUSH_INTERACTIVE=y/' .config && \
    sed -i 's/# CONFIG_HUSH_JOB is not set/CONFIG_HUSH_JOB=y/' .config && \
    # ash shell configuration
    # sed -i 's/# CONFIG_ASH_INTERNAL_GLOB is not set/CONFIG_ASH_INTERNAL_GLOB=y/' .config && \
    # Navigation (history, tab completion)
    sed -i 's/# CONFIG_FEATURE_EDITING is not set/CONFIG_FEATURE_EDITING=y/' .config && \
    sed -i 's/CONFIG_FEATURE_EDITING_MAX_LEN=0/CONFIG_FEATURE_EDITING_MAX_LEN=1024/' .config && \
    sed -i 's/CONFIG_FEATURE_EDITING_HISTORY=0/CONFIG_FEATURE_EDITING_HISTORY=150/' .config && \
    sed -i 's/# CONFIG_FEATURE_TAB_COMPLETION is not set/CONFIG_FEATURE_TAB_COMPLETION=y/' .config && \
    # Lets the shell find 'chmod' internally
    sed -i 's/# CONFIG_FEATURE_SH_STANDALONE is not set/CONFIG_FEATURE_SH_STANDALONE=y/' .config

ARG UTILS
RUN for util in $(echo "$UTILS" | tr '[:lower:]' '[:upper:]'); do \
        sed -i "s/# CONFIG_$util is not set/CONFIG_$util=y/" .config || true; \
    done

RUN make -j$(nproc)


# FROM backplane/upx:latest AS upx
# ARG VERSION_BUSYBOX
# COPY --from=builder /build/busybox-$VERSION_BUSYBOX/busybox /build/busybox-$VERSION_BUSYBOX/busybox
# RUN upx --brute /build/busybox-$VERSION_BUSYBOX/busybox

FROM scratch
ARG VERSION_BUSYBOX
COPY --from=builder /build/busybox-$VERSION_BUSYBOX/busybox /bin/busybox
# Create symlinks to busybox utilities
RUN ["/bin/busybox", "--install", "-s", "/bin"]
ENTRYPOINT ["/bin/sh"]
