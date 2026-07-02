#!/bin/sh
# Build FFmpeg *shared* archives via the BtbN/FFmpeg-Builds submodule (needs bash + docker, e.g. WSL2).
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
# Override via env, e.g.:  VARIANTS="gpl-shared lgpl-shared" VERSIONS="8.0" ./BuildFFmpeg.sh
VARIANTS="${VARIANTS:-gpl-shared}"
VERSIONS="${VERSIONS:-8.0 7.1 7.0 6.1 6.0 5.1 5.0 4.4}"
PLATFORMS="${PLATFORMS:-win64 win32 winarm64 linux64 linuxarm64}"

BUILD_DIR="./FFmpeg-Builds"
ARTIFACTS_DIR="./artifacts"
mkdir -p "$ARTIFACTS_DIR"

docker builder prune -f
for VARIANT in $VARIANTS; do
    for VERSION in $VERSIONS; do
        for PLATFORM in $PLATFORMS; do
            echo -ne "\033]0;FFmpeg Build: $VARIANT $VERSION ($PLATFORM)\007"

            # Skip if this variant/platform/version archive already exists in ./artifacts
            if find "$ARTIFACTS_DIR" -maxdepth 1 -name "ffmpeg-*-$PLATFORM-$VARIANT-$VERSION.*" | grep -q .; then
                continue
            fi

            "$BUILD_DIR/makeimage.sh" "$PLATFORM" "$VARIANT" "$VERSION" || continue
            "$BUILD_DIR/build.sh"     "$PLATFORM" "$VARIANT" "$VERSION" || continue

            # BtbN writes to FFmpeg-Builds/artifacts; move new archives up to ./artifacts
            if [ -d "$BUILD_DIR/artifacts" ]; then
                find "$BUILD_DIR/artifacts" -maxdepth 1 -type f -name "ffmpeg-*" -exec mv -f {} "$ARTIFACTS_DIR/" \;
            fi
            docker builder prune -f
        done
    done
done
