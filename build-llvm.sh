#!/usr/bin/env bash

set -e

function gcl
{
    git clone --recurse-submodules --depth 1 $@
}

[[ -d llvm-source ]] && rm -rf llvm-source
[[ -d llvm-build ]] && rm -rf llvm-build
gcl --branch "esp-16.0.4-20231113" "https://github.com/espressif/llvm-project.git" llvm-source
cmake \
    -S llvm-source/llvm \
    -B llvm-build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DCMAKE_INSTALL_PREFIX=/opt/llvm-xtensa \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_ASM_COMPILER=gcc
cmake --build llvm-build
sudo cmake --install llvm-build
