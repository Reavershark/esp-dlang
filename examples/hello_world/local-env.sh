#!/usr/bin/env -S sh -c "echo Don\\'t run this file, source it!"
source /opt/esp-idf/export.sh >/dev/null
export PATH="/opt/ldc-xtensa/bin:/opt/llvm-xtensa/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/llvm-xtensa/lib/${LD_LIBRARY_PATH}"
export CC="$(which clang)" CXX="$(which clang++)" DC="$(which ldc2)"
