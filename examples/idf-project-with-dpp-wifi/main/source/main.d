module main;

import idf.esp.log : ESP_LOGI;
import utils.simple_wifi : simpleWifiInit;

@safe @nogc nothrow:

extern(C) void app_main() @trusted
{
    ESP_LOGI!"app_main entry";
    simpleWifiInit!("wireless_m", "jonas_en_lars");
    ESP_LOGI!"app_main exit";
}
