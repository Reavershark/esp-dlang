module idfd.wifi_client;

import idfd.util;
import idfd.nvs_flash : initNvsFlash, nvsFlashInitialized;

import idf.esp_common.esp_err : ESP_OK, ESP_ERROR_CHECK;
import idf.esp_event : esp_event_base_t, esp_event_handler_instance_t, ESP_EVENT_ANY_ID,
    esp_event_loop_create_default, esp_event_handler_instance_register;
import idf.freertos : EventGroupHandle_t,
    pdFALSE, portMAX_DELAY,
    xEventGroupCreate, xEventGroupSetBits, xEventGroupWaitBits;
import idf.esp_wifi : esp_wifi_connect, esp_wifi_start,
    WIFI_EVENT, WIFI_EVENT_STA_START, WIFI_EVENT_STA_DISCONNECTED,
    esp_netif_init, esp_netif_create_default_wifi_sta,
    IP_EVENT, IP_EVENT_STA_GOT_IP, ip_event_got_ip_t,
    esp_wifi_init, wifi_init_config_t, WIFI_INIT_CONFIG_DEFAULT,
    esp_wifi_set_mode, esp_wifi_set_config, wifi_config_t, WIFI_AUTH_OPEN, WIFI_AUTH_WEP, WIFI_MODE_STA, WIFI_IF_STA;
import idf.stdio : printf;

@safe:

private enum uint WIFI_CONNECTED_BIT = 1 << 0;
private __gshared EventGroupHandle_t wifiEventGroup;

void simpleWifiInit(string ssid, string password = "")() @trusted
{
    if (!nvsFlashInitialized)
        initNvsFlash!(true);

    wifiEventGroup = xEventGroupCreate;

    assert(esp_netif_init == ESP_OK);

    assert(esp_event_loop_create_default == ESP_OK);
    esp_netif_create_default_wifi_sta;

    wifi_init_config_t cfg_ = WIFI_INIT_CONFIG_DEFAULT;
    printf("magic: %x\n", cfg_.magic);
    printf("Calling esp_wifi_init\n");
    ESP_ERROR_CHECK(esp_wifi_init(&cfg_));

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    assert(esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifiEventHandler, null, &instance_any_id) == ESP_OK);
    assert(esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifiEventHandler, null, &instance_got_ip) == ESP_OK);

    wifi_config_t wifi_config;
    enum immutable(ubyte)[] ssid_bytes = cast(immutable(ubyte)[]) stringzOf!ssid;
    wifi_config.sta.ssid[] = ssid_bytes[];
    static if (password.length >= 0)
    {
        enum immutable(ubyte)[] password_bytes = cast(immutable(ubyte)[]) stringzOf!password;
        wifi_config.sta.password[] = password_bytes[];
        wifi_config.sta.threshold.authmode = WIFI_AUTH_WEP; // Minimum accepted network security
    }
    else
    {
        wifi_config.sta.threshold.authmode = WIFI_AUTH_OPEN; // Minimum accepted network security
    }

    assert(esp_wifi_set_mode(WIFI_MODE_STA) == ESP_OK);
    assert(esp_wifi_set_config(WIFI_IF_STA, &wifi_config) == ESP_OK);
    assert(esp_wifi_start == ESP_OK);

    xEventGroupWaitBits(wifiEventGroup, WIFI_CONNECTED_BIT, pdFALSE, pdFALSE, portMAX_DELAY);
    printf("simpleWifiInit done"); // LOGI
}

private extern (C) void wifiEventHandler(void* arg, esp_event_base_t event_base, int event_id, void* event_data) @trusted
{
    if (event_base == WIFI_EVENT)
    {
        if (event_id == WIFI_EVENT_STA_START)
        {
            printf("Connecting to AP...\n"); // LOGI
            esp_wifi_connect();
        }
        else if (event_id == WIFI_EVENT_STA_DISCONNECTED)
        {
            printf("Failed to connect to AP, retrying...\n"); // LOGW
            esp_wifi_connect();
        }
    }
    else if (event_base == IP_EVENT)
    {
        if (event_id == IP_EVENT_STA_GOT_IP)
        {
            ip_event_got_ip_t* event = cast(ip_event_got_ip_t*) event_data;
            uint* ipPtr = &((*event).ip_info.ip.addr);
            ubyte[] b = (cast(ubyte*) ipPtr)[0 .. 4];
            printf("Connected with ip address: %d.%d.%d.%d", b[0], b[1], b[2], b[3]); // LOGI

            // Signal simpleWifiInit that we are connected
            xEventGroupSetBits(wifiEventGroup, WIFI_CONNECTED_BIT);
        }
    }
}
