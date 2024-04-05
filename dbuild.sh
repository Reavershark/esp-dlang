#!/usr/bin/env bash
export DFLAGS="$(cd .. && dflags.py)"
dub build
    --compiler=/opt/ldc-xtensa/bin/ldc2
    --build=plain
    --color=always
    --cache=local
