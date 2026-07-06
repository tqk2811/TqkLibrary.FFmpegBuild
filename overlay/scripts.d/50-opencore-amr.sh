#!/bin/bash

SCRIPT_REPO="https://git.code.sf.net/p/opencore-amr/code"
SCRIPT_COMMIT="7dba8c32238418ce0b316a852b2224df586ca896"

ffbuild_enabled() {
    # opencore-amr requires FFmpeg's --enable-version3; the gpl2/lgpl2
    # variants build without it, so skip this library there.
    [[ $VARIANT == *gpl2* ]] && return 1
    return 0
}

ffbuild_dockerbuild() {
    autoreconf -i

    local myconf=(
        --prefix="$FFBUILD_PREFIX"
        --disable-shared
        --enable-static
        --with-pic
        --enable-amrnb-encoder
        --enable-amrnb-decoder
        --disable-examples
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
    echo --enable-libopencore-amrnb --enable-libopencore-amrwb
}

ffbuild_unconfigure() {
    echo --disable-libopencore-amrnb --disable-libopencore-amrwb
}
