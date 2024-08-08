FROM ghcr.io/dlang-dockerized/ldc-xtensa:1.39-bookworm

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates wget \
        git python3 python-is-python3 python3-pip python3-virtualenv cmake ninja-build libusb-1.0-0 && \
    rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone \
        --recurse-submodules \
        --depth 1 \
        --branch "v4.4.8" \
        "https://github.com/espressif/esp-idf.git" \
        esp-idf
RUN /opt/esp-idf/install.sh

COPY ./list_idf_include_paths.py /usr/local/bin/

WORKDIR /work
