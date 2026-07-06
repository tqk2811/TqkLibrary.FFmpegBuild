#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/defaults-lgpl2.sh
FF_CONFIGURE+=" --enable-shared --disable-static"
