module idf.esp.wifi;

public import idf.esp.wifi.includes_dpp;

@safe @nogc nothrow:

wifi_init_config_t WIFI_INIT_CONFIG_DEFAULT() @trusted
{
    wifi_init_config_t cfg;
    cfg.osi_funcs = &g_wifi_osi_funcs;
    cfg.wpa_crypto_funcs = g_wifi_default_wpa_crypto_funcs;
    cfg.static_rx_buf_num = CONFIG_ESP32_WIFI_STATIC_RX_BUFFER_NUM;
    cfg.dynamic_rx_buf_num = CONFIG_ESP32_WIFI_DYNAMIC_RX_BUFFER_NUM;
    cfg.tx_buf_type = CONFIG_ESP32_WIFI_TX_BUFFER_TYPE;
    cfg.static_tx_buf_num = WIFI_STATIC_TX_BUFFER_NUM;
    cfg.dynamic_tx_buf_num = WIFI_DYNAMIC_TX_BUFFER_NUM;
    cfg.cache_tx_buf_num = WIFI_CACHE_TX_BUFFER_NUM;
    cfg.csi_enable = WIFI_CSI_ENABLED;
    cfg.ampdu_rx_enable = WIFI_AMPDU_RX_ENABLED;
    cfg.ampdu_tx_enable = WIFI_AMPDU_TX_ENABLED;
    cfg.amsdu_tx_enable = WIFI_AMSDU_TX_ENABLED;
    cfg.nvs_enable = WIFI_NVS_ENABLED;
    cfg.nano_enable = WIFI_NANO_FORMAT_ENABLED;
    cfg.rx_ba_win = WIFI_DEFAULT_RX_BA_WIN;
    cfg.wifi_task_core_id = WIFI_TASK_CORE_ID;
    cfg.beacon_max_len = WIFI_SOFTAP_BEACON_MAX_LEN;
    cfg.mgmt_sbuf_num = WIFI_MGMT_SBUF_NUM;
    cfg.feature_caps = g_wifi_feature_caps;
    cfg.sta_disconnected_pm = WIFI_STA_DISCONNECTED_PM_ENABLED;
    cfg.espnow_max_encrypt_num = CONFIG_ESP_WIFI_ESPNOW_MAX_ENCRYPT_NUM;
    cfg.magic = WIFI_INIT_CONFIG_MAGIC;
    return cfg;
}
