#!/usr/bin/env -S sh -c "echo Don\\'t run this file, source it!"
source /opt/esp-idf/export.sh >/dev/null
export PATH="/opt/ldc-xtensa/bin:/opt/llvm-xtensa/bin:${PATH}"
export CC="clang" CXX="clang++" DC="ldc2"
