# Todo: remove python where possible (ldc bootstrap?)

ARG LLVM_VERSION="esp-16.0.4-20231113"
ARG LDC_VERSION="v1.37.0"
ARG ESP_IDF_VERSION="v5.2.1"

# Build llvm-xtensa
FROM ubuntu:22.04 AS build-stage-llvm-xtensa
ARG LLVM_VERSION

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates git \
        binutils gcc g++ gdmd cmake ninja-build python3 && \
    rm -rf /var/lib/apt/lists/*
ENV CC=gcc \
    CXX=g++

WORKDIR /build
RUN git clone \
        --recurse-submodules \
        --depth 1 \
        --branch "${LLVM_VERSION}" \
        "https://github.com/espressif/llvm-project.git" \
        llvm-source && \
    cmake \
        -S llvm-source/llvm \
        -B llvm-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
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
        -DLLVM_ENABLE_PROJECTS="clang;lld" && \
    cmake --build llvm-build && \
    cmake --install llvm-build && \
    rm -r llvm-source llvm-build


# Build ldc-xtensa-bootstrap
FROM ubuntu:22.04 AS build-stage-ldc-xtensa-bootstrap
ARG LDC_VERSION

COPY --from=build-stage-llvm-xtensa /opt/llvm-xtensa /opt/llvm-xtensa
RUN echo "/opt/llvm-xtensa/lib" > /etc/ld.so.conf.d/llvm-xtensa.conf && \
    ldconfig
ENV PATH="/opt/llvm-xtensa/bin:${PATH}" \
    CC=clang \
    CXX=clang++

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates git \
        binutils gdmd cmake ninja-build python3 && \
    rm -rf /var/lib/apt/lists/*
ENV DC=gdmd

RUN git clone \
        --recurse-submodules \
        --depth 1 \
        --branch "${LDC_VERSION}" \
        "https://github.com/ldc-developers/ldc.git" \
        ldc-source && \
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
        -DLLVM_ROOT_DIR=/opt/llvm-xtensa && \
    cmake --build ldc-build && \
    cmake --install ldc-build && \
    rm -r ldc-source ldc-build


# Build ldc-xtensa
FROM ubuntu:22.04 AS build-stage-ldc-xtensa
ARG LDC_VERSION

COPY --from=build-stage-llvm-xtensa /opt/llvm-xtensa /opt/llvm-xtensa
RUN echo "/opt/llvm-xtensa/lib" > /etc/ld.so.conf.d/llvm-xtensa.conf && \
    ldconfig
ENV PATH="/opt/llvm-xtensa/bin:${PATH}" \
    CC=clang \
    CXX=clang++

COPY --from=build-stage-ldc-xtensa-bootstrap /opt/ldc-xtensa-bootstrap /opt/ldc-xtensa-bootstrap
RUN echo "/opt/ldc-xtensa-bootstrap/lib" > /etc/ld.so.conf.d/ldc-xtensa-bootstrap.conf && \
    ldconfig
ENV PATH="/opt/ldc-xtensa-bootstrap/bin:${PATH}" \
    DC="ldmd2"

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates git \
        binutils libc-dev libstdc++-11-dev libgcc-11-dev libgphobos2 cmake ninja-build && \
    rm -rf /var/lib/apt/lists/*

RUN git clone \
        --recurse-submodules \
        --depth 1 \
        --branch "${LDC_VERSION}" \
        "https://github.com/ldc-developers/ldc.git" \
        ldc-source && \
    cmake \
        -S ldc-source \
        -B ldc-build \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=/opt/ldc-xtensa \
        -DCMAKE_C_COMPILER="${CC}" \
        -DCMAKE_CXX_COMPILER="${CXX}" \
        -DCMAKE_ASM_COMPILER="${CC}" \
        -DD_COMPILER="${DC}" \
        -DLLVM_ROOT_DIR=/opt/llvm-xtensa && \
    cmake --build ldc-build && \
    cmake --install ldc-build && \
    rm -r ldc-source ldc-build


# Trim llvm directory a bit
FROM build-stage-llvm-xtensa AS build-stage-llvm-xtensa-trimmed
RUN cd /opt/llvm-xtensa && \
    rm -r \
        include libexec share \
        bin/c-index-test bin/llvm-exegesis \
        lib/*.a \
        lib/cmake lib/libear lib/libscanbuild


# Construct export stage
FROM ubuntu:22.04 AS export-stage
ARG ESP_IDF_VERSION

COPY --from=build-stage-llvm-xtensa-trimmed /opt/llvm-xtensa /opt/llvm-xtensa
RUN echo "/opt/llvm-xtensa/lib" > /etc/ld.so.conf.d/llvm-xtensa.conf && \
    ldconfig
ENV PATH="/opt/llvm-xtensa/bin:${PATH}" \
    CC=clang \
    CXX=clang++

COPY --from=build-stage-ldc-xtensa /opt/ldc-xtensa /opt/ldc-xtensa
RUN echo "/opt/ldc-xtensa/lib" > /etc/ld.so.conf.d/ldc-xtensa.conf && \
    ldconfig
ENV PATH="/opt/ldc-xtensa/bin:${PATH}" \
    DC="ldc2"

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates wget \
        binutils libc-dev libstdc++-11-dev libgcc-11-dev \
        git python3 python-is-python3 python3-pip python3-venv cmake ninja-build libusb-1.0-0 && \
    wget "https://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list" -O /etc/apt/sources.list.d/d-apt.list && \
    apt-get update --allow-insecure-repositories && \
    apt-get -y --allow-unauthenticated install \
        d-apt-keyring && \
    apt-get update && \
    apt-get -y install \
        dub && \
    rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone \
        --recurse-submodules \
        --depth 1 \
        --branch "${ESP_IDF_VERSION}" \
        "https://github.com/espressif/esp-idf.git" \
        esp-idf && \
    /opt/esp-idf/install.sh

COPY ./dflags.py /opt/ldc-xtensa/bin/dflags.py

WORKDIR /work

# echo "\necho Sourcing /opt/esp-idf/export.sh\nsource /opt/esp-idf/export.sh >/dev/null" >> /etc/bash.bashrc
