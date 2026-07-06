#!/bin/sh
# Apply the tracked overlay/ onto the pristine BtbN/FFmpeg-Builds submodule.
#
# The submodule is kept PRISTINE in git (recorded commit only). Our customizations
# live in ./overlay and are copied in at build time by this script:
#   - variants/*gpl2*,*lgpl2* : GPL v2 / LGPL v2.1 variant + defaults files
#   - scripts.d/*             : license/version3/openssl/sdl2 guards
#   - images/base*/Dockerfile : nproc cap + kernel-4.18 pre-seed (RAM/kernel.org fixes)
#   - makeimage.sh            : buildkit max-parallelism=1 (RAM safety)
#
# RunOvernight.sh and BuildFFmpeg.sh call this automatically before building.
# To restore the submodule to pristine afterwards:
#   git -C FFmpeg-Builds checkout -- . && git -C FFmpeg-Builds clean -fd variants
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_DIR="$REPO_DIR/overlay"
SUBMODULE_DIR="$REPO_DIR/FFmpeg-Builds"

if [ ! -d "$SUBMODULE_DIR/scripts.d" ]; then
    echo "ERROR: FFmpeg-Builds submodule not populated at $SUBMODULE_DIR" >&2
    echo "       run: git submodule update --init" >&2
    exit 1
fi

cp -R "$OVERLAY_DIR/." "$SUBMODULE_DIR/"
echo "apply-overlay: copied $(find "$OVERLAY_DIR" -type f | wc -l | tr -d ' ') files into FFmpeg-Builds/"
