#!/usr/bin/env rdmd

import std.algorithm : map;
import std.array : appender, array;
import std.file : dirEntries, SpanMode, DirEntry, exists;
import std.format : f = format;
import std.parallelism : parallel;
import std.process : env = environment, execute;
import std.range : empty;
import std.stdio;

void main()
{
  pragma(msg, "Compiling dpp_build.d");
  writeln("Running dpp_build.d");

  string[] fileList = buildFileList;
  if (!fileList.empty)
  {
    auto dubRunPart = ["dub", "run", "--yes", "--build=release", "--compiler=dmd", "dpp@0.5.2", "--"];
    auto dppSingleArgsPart = ["-n", "--preprocess-only"];
    auto commandWithoutFiles = dubRunPart ~ dppSingleArgsPart ~ defineArgs ~ ignoreSymbolArgs ~ includeArgs;
    foreach(file; parallel(fileList))
    {
        writefln!"Processing file \"%s\""(file);
        auto result = execute(commandWithoutFiles ~ file);
        if (result.status != 0)
            throw new Exception(f!"Error executing command: %s"(result.output));
        writefln!"Finished processing file \"%s\""(file);
    }
  }
}

string[] buildFileList()
{
  string[] list;
  foreach (DirEntry dpp_dpp_entry; dirEntries("source", "*_dpp.dpp", SpanMode.depth))
  {
    string dpp_d_name = dpp_dpp_entry.name[0 .. $ - 4] ~ ".d";
    if (exists(dpp_d_name))
    {
      DirEntry dpp_d_entry = DirEntry(dpp_d_name);
      // if newer than source, skip
      if (dpp_d_entry.timeLastModified > dpp_dpp_entry.timeLastModified)
        continue;
    }
    list ~= dpp_dpp_entry.name;
  }
  return list;
}

string[] defineArgs()
{
    auto defines = appender!(string[]);
    defines ~= "__XTENSA__";
    return defines[]
        .map!((string define) => "--define=" ~ define)
        .array;
}

string[] ignoreSymbolArgs()
{
    auto symbols = appender!(string[]);
    symbols ~= "__assert";
    return symbols[]
        .map!((string symbol) => "--ignore-cursor=" ~ symbol)
        .array;
}

string[] includeArgs()
{
    auto includePaths = appender!(string[]);
    includePaths ~= "../build/config";
    includePaths ~= env["HOME"] ~ "/.espressif/tools/riscv32-esp-elf/esp-2022r1-11.2.0/riscv32-esp-elf/riscv32-esp-elf/include";
    foreach (componentIncludePath; [
        "newlib/platform_include", "freertos/FreeRTOS-Kernel/include", "freertos/esp_additions/include/freertos",
        "freertos/FreeRTOS-Kernel/portable/xtensa/include", "freertos/esp_additions/include", "esp_hw_support/include",
        "esp_hw_support/include/soc", "esp_hw_support/include/soc/esp32", "esp_hw_support/port/esp32/.",
        "esp_hw_support/port/esp32/private_include", "heap/include", "log/include", "soc/include", "soc/esp32/.",
        "soc/esp32/include", "hal/esp32/include", "hal/include", "hal/platform_port/include", "esp_rom/include",
        "esp_rom/include/esp32", "esp_rom/esp32", "esp_common/include", "esp_system/include", "esp_system/port/soc",
        "esp_system/port/include/private", "xtensa/include", "xtensa/esp32/include", "lwip/include", "lwip/include/apps",
        "lwip/include/apps/sntp", "lwip/lwip/src/include", "lwip/port/esp32/include", "lwip/port/esp32/include/arch",
        "esp_ringbuf/include", "efuse/include", "efuse/esp32/include", "driver/include", "driver/deprecated", "driver/esp32/include",
        "esp_pm/include", "mbedtls/port/include", "mbedtls/mbedtls/include", "mbedtls/mbedtls/library", "mbedtls/esp_crt_bundle/include",
        "esp_app_format/include", "bootloader_support/include", "bootloader_support/bootloader_flash/include", "esp_partition/include",
        "app_update/include", "spi_flash/include", "pthread/include", "esp_timer/include", "app_trace/include", "esp_event/include",
        "nvs_flash/include", "esp_phy/include", "esp_phy/esp32/include", "vfs/include", "esp_netif/include", "wpa_supplicant/include",
        "wpa_supplicant/port/include", "wpa_supplicant/esp_supplicant/include", "esp_wifi/include", "unity/include", "unity/unity/src",
        "cmock/CMock/src", "console", "http_parser", "esp-tls", "esp-tls/esp-tls-crypto", "esp_adc/include", "esp_adc/interface",
        "esp_adc/esp32/include", "esp_adc/deprecated/include", "esp_eth/include", "esp_gdbstub/include", "esp_gdbstub/xtensa",
        "esp_gdbstub/esp32", "esp_hid/include", "tcp_transport/include", "esp_http_client/include", "esp_http_server/include",
        "esp_https_ota/include", "esp_lcd/include", "esp_lcd/interface", "protobuf-c/protobuf-c", "protocomm/include/common",
        "protocomm/include/security", "protocomm/include/transports", "esp_local_ctrl/include", "esp_psram/include",
        "espcoredump/include", "espcoredump/include/port/xtensa", "wear_levelling/include", "sdmmc/include", "fatfs/diskio",
        "fatfs/vfs", "fatfs/src", "idf_test/include", "idf_test/include/esp32", "ieee802154/include", "json/cJSON",
        "mqtt/esp-mqtt/include", "perfmon/include", "spiffs/include", "ulp/ulp_common/include", "ulp/ulp_common/include/esp32",
        "wifi_provisioning/include"
    ])
    {
        includePaths ~= "/opt/esp-idf/components/" ~ componentIncludePath;
    }
    return includePaths[]
        .map!((string path) => "--include-path=" ~ path)
        .array;
}
