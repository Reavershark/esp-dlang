###############
# build stage #
###############

FROM ubuntu:22.04 AS build-stage

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        build-essential git cmake ninja-build python3 ca-certificates gdmd && \
    rm -rf /var/lib/apt/lists/*

RUN echo -e '#!/usr/bin/env bash\nset -e\nexec $@' > /usr/local/bin/sudo && \
    chmod +x /usr/local/bin/sudo

WORKDIR /build
COPY ./build-toolchain.sh /build/build-toolchain.sh
RUN chmod +x build-toolchain.sh

RUN ./build-toolchain.sh

################
# export stage #
################

FROM ubuntu:22.04 AS export-stage

# gcc & phobos for shared libraries for running x86 executables
# clang is a dependency of dpp
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends \
        gcc libgphobos2 ca-certificates wget \
        clang libclang-dev && \
    wget "https://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list" -O /etc/apt/sources.list.d/d-apt.list && \
    apt-get update --allow-insecure-repositories && \
    apt-get -y --allow-unauthenticated install --reinstall \
        d-apt-keyring && \
    apt-get update && \
    apt-get -y install \
        dmd-compiler dub && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/lib/llvm-14/lib/libclang.so /usr/lib/ && \
    dub build -y --build=release --compiler=dmd dpp@0.5.2

COPY --from=build-stage /opt/llvm-xtensa /opt/llvm-xtensa
COPY --from=build-stage /opt/ldc-xtensa /opt/ldc-xtensa

ENV DC=/opt/ldc-xtensa/bin/ldc2
COPY ./ldc2.conf /opt/ldc-xtensa/etc/ldc2.conf

WORKDIR /work
