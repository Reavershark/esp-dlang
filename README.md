# Dlang esp toolchain

## Obtaining

### Docker

```
docker pull jmeeuws/esp-dlang
```

### Locally

For a better development experience, you might want to copy the toolchain out of the docker image.
This is done by running a temporary container and copying over the relevant directories from it:

```
docker container run --rm -d --name temp jmeeuws/esp-dlang sleep inf
docker container cp temp:/opt/ldc /opt/ldc-xtensa
docker container cp temp:/opt/esp-idf /opt/esp-idf
docker container kill temp
```

You might also want to grab all llvm tools for debugging purposes:


```
docker container run --rm -d --name temp dlang-dockerized/llvm-xtensa sleep inf
docker container cp temp:/opt/llvm /opt/llvm-xtensa
docker container kill temp
```

## Usage

Open a shell in one of the example folders, then run either `./docker-env.sh` or `source local-env.sh`.

Build with `dub build --deep -axtensa-esp32-none-elf --build=debug`.

Flash with `(cd idf-project/debug && idf.py flash -b 460800 && idf.py monitor)` (Make sure to ground GPIO0 during this command).

(For cpus other than the original esp32, run `(cd idf-project/debug && idf.py set-target esp32xx)` first. You might also want to modify ldc2.conf.)

## Sources

https://wiki.dlang.org/D_on_esp32/esp8266(llvm-xtensa%2Bldc)_and_how_to_get_started.
