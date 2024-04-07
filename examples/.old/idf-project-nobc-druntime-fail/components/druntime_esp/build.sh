#!/usr/bin/env bash

set -e

function gcl
{
    git clone --recurse-submodules --depth 1 $@
}

gcl --branch "v1.33.0-beta1" "https://github.com/ldc-developers/ldc.git" ldc-source

grep -rl 'Posix' ldc-source | xargs sed -i 's/Posix/ESP_IDF/g'
grep -rl 'linux' ldc-source | xargs sed -i 's/linux/ESP_IDF/g'
grep -rl 'CRuntime_Glibc' ldc-source | xargs sed -i 's/CRuntime_Glibc/ESP_IDF/g'
grep -rl 'RISCV_Any' ldc-source | xargs sed -i 's/RISCV_Any/ESP_IDF/g'
grep -rl 'RISCV32' ldc-source | xargs sed -i 's/RISCV32/ESP_IDF/g'
grep -rl 'pragma(printf)' ldc-source | xargs sed -i 's/pragma(printf)//g'
grep -rl 'pragma(scanf)' ldc-source | xargs sed -i 's/pragma(scanf)//g'
patch -p0 < osthread.patch

mkdir build
cp -r ldc-source/runtime/druntime/src build/source
cat > build/dub.sdl <<EOF 
name "druntime_esp"                 
targetType "staticLibrary"
versions "ESP_IDF"
buildRequirements "allowWarnings"
EOF

dub build --root=build --compiler=/opt/ldc-xtensa/bin/ldc2 --build=release

cp build/libdruntime_esp.a libdruntime_esp.a

rm ldc-source -rf
rm build -rf
