#!/bin/bash

SCRIPT_REPO="https://github.com/BtbN/gmplib.git"
SCRIPT_COMMIT="9994908f090c694f8a152d660dc6852e0c48557a"

ffbuild_enabled() {
    # gmp is gated behind FFmpeg's --enable-version3; the gpl2/lgpl2 variants
    # build without it (and nothing else depends on gmp), so skip it there.
    [[ $VARIANT == *gpl2* ]] && return 1
    return 0
}

ffbuild_dockerbuild() {
    ./.bootstrap

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --enable-maintainer-mode
        --disable-shared
        --enable-static
        --with-pic
    )

    if [[ $TARGET == win* || $TARGET == linux* ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
        )
    else
        echo "Unknown target"
        return -1
    fi

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="$FFBUILD_DESTDIR"
}

ffbuild_configure() {
    echo --enable-gmp
}

ffbuild_unconfigure() {
    echo --disable-gmp
}
