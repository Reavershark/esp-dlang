module main;

import idf.esp_event;

import idf.esp_wifi : WIFI_INIT_CONFIG_DEFAULT;

@safe:

extern(C) void app_main() @trusted
{
    auto conf = WIFI_INIT_CONFIG_DEFAULT();
}
