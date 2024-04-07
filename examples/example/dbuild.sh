#!/usr/bin/env bash

# Config
target="esp32"
DFLAGS+=" --linkonce-templates"
DFLAGS+=" --preview=dip1000"

set -e

# Append default flags based on target
DFLAGS+=" $(cd "$(dirname "${BASH_SOURCE[0]}")" && dflags.py "${target}")"
export DFLAGS

dub build \
    --build=plain \
    --cache=local \
    --color=always
