#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-gpl2.sh
FF_CONFIGURE+=" --enable-shared --disable-static"
