#!/usr/bin/env bash

set -e

LLVM_VERSION="esp-16.0.4-20231113"
LDC_VERSION="v1.37.0"
CC="gcc"
CXX="g++"
DC="gdmd"

for cmd in "${CC}" "${CXX}" "${DC}"; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo Command "${cmd}" not found.
        echo Exiting...
        exit 1
    fi
done

if command -v ldc2 &>/dev/null; then
    echo Uninstall ldc before building to avoid bad linkage.
    echo Feel free to reinstall your system ldc later.
    echo Exiting...
    exit 2
fi

[[ -d llvm-source ]] && rm -rf llvm-source
[[ -d llvm-build ]] && rm -rf llvm-build
git clone \
    --recurse-submodules \
    --depth 1 \
    --branch "${LLVM_VERSION}" \
    "https://github.com/espressif/llvm-project.git" \
    llvm-source
cmake \
    -S llvm-source/llvm \
    -B llvm-build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/opt/llvm-xtensa \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_ASM_COMPILER="${CC}" \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_BUILD_UTILS=OFF \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="Xtensa" \
    -DLLVM_ENABLE_PROJECTS="clang;lld"
cmake --build llvm-build
cmake --install llvm-build

PATH="/opt/llvm-xtensa/bin:${PATH}"
CC="clang"
CXX="clang++"

[[ -d ldc-source ]] && rm -rf ldc-source
[[ -d ldc-build ]] && rm -rf ldc-build
git clone \
    --recurse-submodules \
    --depth 1 \
    --branch "${LDC_VERSION}" \
    "https://github.com/ldc-developers/ldc.git" \
    ldc-source
cmake \
    -S ldc-source \
    -B ldc-build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/opt/ldc-xtensa-bootstrap \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_ASM_COMPILER="${CC}" \
    -DD_COMPILER="${DC}" \
    -DLLVM_ROOT_DIR=/opt/llvm-xtensa
cmake --build ldc-build
cmake --install ldc-build

cp ./dflags.py /opt/ldc-xtensa/bin/
