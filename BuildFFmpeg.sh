#!/bin/sh
# Build FFmpeg *shared* archives via the BtbN/FFmpeg-Builds submodule (needs bash + docker, e.g. an Ubuntu VM).
# Collected archives go into ./artifacts (git-ignored); AutoPackager reads that folder.
#
# Variants:
#   gpl-shared   -> GPL v3    (BtbN default: --enable-gpl --enable-version3)
#   lgpl-shared  -> LGPL v3   (BtbN default: --enable-version3; lacks libx264/libx265)
#   gpl2-shared  -> GPL v2    (CUSTOM: add variants/<target>-gpl2-shared.sh to the submodule,
#                              without --enable-version3 and dropping version3-only deps
#                              such as libopencore-amr and libaribb24)
#   lgpl2-shared -> LGPL v2.1 (CUSTOM: same idea, LGPL base is 2.1)
#
# Run from the repo root, inside a bash+docker environment. Override via env, e.g.:
#   VARIANTS="gpl-shared lgpl-shared" VERSIONS="8.0" PLATFORMS="win64" ./BuildFFmpeg.sh
VARIANTS="${VARIANTS:-gpl-shared}"
VERSIONS="${VERSIONS:-8.0 7.1 7.0 6.1 6.0 5.1 5.0 4.4}"
PLATFORMS="${PLATFORMS:-win64 win32 winarm64 linux64 linuxarm64}"

BUILD_DIR="./FFmpeg-Builds"
ARTIFACTS_DIR="./artifacts"
CACHE_BASE_DIR="$BUILD_DIR/.cache/ghcr.io/btbn/ffmpeg-builds"
mkdir -p "$ARTIFACTS_DIR"

docker builder prune -f
for VARIANT in $VARIANTS; do
    for VERSION in $VERSIONS; do
        for PLATFORM in $PLATFORMS; do
            printf '\033]0;FFmpeg Build: %s %s (%s)\007' "$VARIANT" "$VERSION" "$PLATFORM"

            # Skip if this variant/platform/version archive already exists in ./artifacts
            if find "$ARTIFACTS_DIR" -maxdepth 1 -name "ffmpeg-*-$PLATFORM-$VARIANT-$VERSION.*" | grep -q .; then
                continue
            fi

            # Skip cleanly if the variant is not defined in the submodule
            # (e.g. custom gpl2-shared/lgpl2-shared that has not been created yet)
            if [ ! -f "$BUILD_DIR/variants/${PLATFORM}-${VARIANT}.sh" ]; then
                echo "SKIP: missing variant $BUILD_DIR/variants/${PLATFORM}-${VARIANT}.sh"
                continue
            fi

            # Drop the cached built image for this combo so it is rebuilt fresh (keeps disk usage down)
            TARGET_CACHE="$CACHE_BASE_DIR/${PLATFORM}-${VARIANT}-${VERSION}_latest"
            [ -d "$TARGET_CACHE" ] && rm -rf "$TARGET_CACHE"

            "$BUILD_DIR/makeimage.sh" "$PLATFORM" "$VARIANT" "$VERSION"
            "$BUILD_DIR/build.sh"     "$PLATFORM" "$VARIANT" "$VERSION"

            # BtbN writes to FFmpeg-Builds/artifacts; move new archives up to ./artifacts
            if [ -d "$BUILD_DIR/artifacts" ]; then
                find "$BUILD_DIR/artifacts" -maxdepth 1 -type f -name "ffmpeg-*" -exec mv -f {} "$ARTIFACTS_DIR/" \;
            fi

            [ -d "$TARGET_CACHE" ] && rm -rf "$TARGET_CACHE"
            docker builder prune -f
        done
    done
done
