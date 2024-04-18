#include "esp_wifi.h"

wifi_init_config_t WIFI_INIT_CONFIG_DEFAULT_CFunc()
{
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    return cfg;
}
