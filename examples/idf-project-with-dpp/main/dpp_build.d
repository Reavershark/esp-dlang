#!/usr/bin/env rdmd

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.format : f = format;

void main()
{
  pragma(msg, "Compiling dpp_build.d");
  writeln("Running dpp_build.d");

  auto list = fileList;
  if (!list.empty)
  {
    auto result = executeShell("dub run -y --build=release --compiler=dmd dpp@0.5.2 -- -n --preprocess-only --define __XTENSA__ " ~ includes ~ " " ~ list.join(" "));
    if (result.status != 0)
        throw new Exception(f!"Error executing command: %s"(result.output));
  }
}

string[] fileList()
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

enum includes = " --include-path /home/jonas/.espressif/tools/riscv32-esp-elf/esp-2022r1-11.2.0/riscv32-esp-elf/riscv32-esp-elf/include --include-path /hdd/ProjectsHDD/esp-dlang/esp-dlang/examples/idf-project-with-dpp/build/config --include-path /opt/esp-idf/components/newlib/platform_include --include-path /opt/esp-idf/components/freertos/FreeRTOS-Kernel/include --include-path /opt/esp-idf/components/freertos/esp_additions/include/freertos --include-path /opt/esp-idf/components/freertos/FreeRTOS-Kernel/portable/xtensa/include --include-path /opt/esp-idf/components/freertos/esp_additions/include --include-path /opt/esp-idf/components/esp_hw_support/include --include-path /opt/esp-idf/components/esp_hw_support/include/soc --include-path /opt/esp-idf/components/esp_hw_support/include/soc/esp32 --include-path /opt/esp-idf/components/esp_hw_support/port/esp32/. --include-path /opt/esp-idf/components/esp_hw_support/port/esp32/private_include --include-path /opt/esp-idf/components/heap/include --include-path /opt/esp-idf/components/log/include --include-path /opt/esp-idf/components/soc/include --include-path /opt/esp-idf/components/soc/esp32/. --include-path /opt/esp-idf/components/soc/esp32/include --include-path /opt/esp-idf/components/hal/esp32/include --include-path /opt/esp-idf/components/hal/include --include-path /opt/esp-idf/components/hal/platform_port/include --include-path /opt/esp-idf/components/esp_rom/include --include-path /opt/esp-idf/components/esp_rom/include/esp32 --include-path /opt/esp-idf/components/esp_rom/esp32 --include-path /opt/esp-idf/components/esp_common/include --include-path /opt/esp-idf/components/esp_system/include --include-path /opt/esp-idf/components/esp_system/port/soc --include-path /opt/esp-idf/components/esp_system/port/include/private --include-path /opt/esp-idf/components/xtensa/include --include-path /opt/esp-idf/components/xtensa/esp32/include --include-path /opt/esp-idf/components/lwip/include --include-path /opt/esp-idf/components/lwip/include/apps --include-path /opt/esp-idf/components/lwip/include/apps/sntp --include-path /opt/esp-idf/components/lwip/lwip/src/include --include-path /opt/esp-idf/components/lwip/port/esp32/include --include-path /opt/esp-idf/components/lwip/port/esp32/include/arch --include-path /opt/esp-idf/components/esp_ringbuf/include --include-path /opt/esp-idf/components/efuse/include --include-path /opt/esp-idf/components/efuse/esp32/include --include-path /opt/esp-idf/components/driver/include --include-path /opt/esp-idf/components/driver/deprecated --include-path /opt/esp-idf/components/driver/esp32/include --include-path /opt/esp-idf/components/esp_pm/include --include-path /opt/esp-idf/components/mbedtls/port/include --include-path /opt/esp-idf/components/mbedtls/mbedtls/include --include-path /opt/esp-idf/components/mbedtls/mbedtls/library --include-path /opt/esp-idf/components/mbedtls/esp_crt_bundle/include --include-path /opt/esp-idf/components/esp_app_format/include --include-path /opt/esp-idf/components/bootloader_support/include --include-path /opt/esp-idf/components/bootloader_support/bootloader_flash/include --include-path /opt/esp-idf/components/esp_partition/include --include-path /opt/esp-idf/components/app_update/include --include-path /opt/esp-idf/components/spi_flash/include --include-path /opt/esp-idf/components/pthread/include --include-path /opt/esp-idf/components/esp_timer/include --include-path /opt/esp-idf/components/app_trace/include --include-path /opt/esp-idf/components/esp_event/include --include-path /opt/esp-idf/components/nvs_flash/include --include-path /opt/esp-idf/components/esp_phy/include --include-path /opt/esp-idf/components/esp_phy/esp32/include --include-path /opt/esp-idf/components/vfs/include --include-path /opt/esp-idf/components/esp_netif/include --include-path /opt/esp-idf/components/wpa_supplicant/include --include-path /opt/esp-idf/components/wpa_supplicant/port/include --include-path /opt/esp-idf/components/wpa_supplicant/esp_supplicant/include --include-path /opt/esp-idf/components/esp_wifi/include --include-path /opt/esp-idf/components/unity/include --include-path /opt/esp-idf/components/unity/unity/src --include-path /opt/esp-idf/components/cmock/CMock/src --include-path /opt/esp-idf/components/console --include-path /opt/esp-idf/components/http_parser --include-path /opt/esp-idf/components/esp-tls --include-path /opt/esp-idf/components/esp-tls/esp-tls-crypto --include-path /opt/esp-idf/components/esp_adc/include --include-path /opt/esp-idf/components/esp_adc/interface --include-path /opt/esp-idf/components/esp_adc/esp32/include --include-path /opt/esp-idf/components/esp_adc/deprecated/include --include-path /opt/esp-idf/components/esp_eth/include --include-path /opt/esp-idf/components/esp_gdbstub/include --include-path /opt/esp-idf/components/esp_gdbstub/xtensa --include-path /opt/esp-idf/components/esp_gdbstub/esp32 --include-path /opt/esp-idf/components/esp_hid/include --include-path /opt/esp-idf/components/tcp_transport/include --include-path /opt/esp-idf/components/esp_http_client/include --include-path /opt/esp-idf/components/esp_http_server/include --include-path /opt/esp-idf/components/esp_https_ota/include --include-path /opt/esp-idf/components/esp_lcd/include --include-path /opt/esp-idf/components/esp_lcd/interface --include-path /opt/esp-idf/components/protobuf-c/protobuf-c --include-path /opt/esp-idf/components/protocomm/include/common --include-path /opt/esp-idf/components/protocomm/include/security --include-path /opt/esp-idf/components/protocomm/include/transports --include-path /opt/esp-idf/components/esp_local_ctrl/include --include-path /opt/esp-idf/components/esp_psram/include --include-path /opt/esp-idf/components/espcoredump/include --include-path /opt/esp-idf/components/espcoredump/include/port/xtensa --include-path /opt/esp-idf/components/wear_levelling/include --include-path /opt/esp-idf/components/sdmmc/include --include-path /opt/esp-idf/components/fatfs/diskio --include-path /opt/esp-idf/components/fatfs/vfs --include-path /opt/esp-idf/components/fatfs/src --include-path /opt/esp-idf/components/idf_test/include --include-path /opt/esp-idf/components/idf_test/include/esp32 --include-path /opt/esp-idf/components/ieee802154/include --include-path /opt/esp-idf/components/json/cJSON --include-path /opt/esp-idf/components/mqtt/esp-mqtt/include --include-path /opt/esp-idf/components/perfmon/include --include-path /opt/esp-idf/components/spiffs/include --include-path /opt/esp-idf/components/ulp/ulp_common/include --include-path /opt/esp-idf/components/ulp/ulp_common/include/esp32 --include-path /opt/esp-idf/components/wifi_provisioning/include ";

