#!/usr/bin/env bash

set -e

function gcl
{
    git clone --recurse-submodules --depth 1 $@
}

[[ -d ldc-source ]] && rm -rf ldc-source
[[ -d ldc-build ]] && rm -rf ldc-build
gcl --branch "v1.37.0" "https://github.com/ldc-developers/ldc.git" ldc-source
cmake \
    -S ldc-source \
    -B ldc-build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/ldc-xtensa \
    -DLLVM_ROOT_DIR=/opt/llvm-xtensa \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_ASM_COMPILER=gcc
cmake --build ldc-build
sudo cmake --install ldc-build
