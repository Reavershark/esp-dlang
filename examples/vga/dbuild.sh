#!/usr/bin/env bash

set -e

# Config
DFLAGS+=" --linkonce-templates"
DFLAGS+=" --preview=in"
DFLAGS+=" --preview=bitfields"
DFLAGS+=" --preview=fixImmutableConv"
DFLAGS+=" --gc"
# DFLAGS+=" --O3 --boundscheck=off"

# Append default flags based on target
DFLAGS+=" $(cd "$(dirname "${BASH_SOURCE[0]}")" && dflags.py)"
export DFLAGS

dub build \
    --build=plain \
    --cache=local \
    --color=always
