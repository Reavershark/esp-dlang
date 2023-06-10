module idfd.nvs_flash;

import idf.nvs_flash;

import idf.esp_log : ESP_LOGI;

@safe:

__gshared bool nvsFlashInitialized = false;

void initNvsFlash(bool eraseIfNeeded = true)() @trusted
{
    ESP_LOGI!"Initializing NVS Flash...";
    static if (!eraseIfNeeded)
    {
        assert(nvs_flash_init == ESP_OK);
    }
    else
    {
        esp_err_t firstInitResult = nvs_flash_init;
        if (firstInitResult == ESP_ERR_NVS_NO_FREE_PAGES || firstInitResult == ESP_ERR_NVS_NEW_VERSION_FOUND)
        {
          assert(nvs_flash_erase == ESP_OK);
          assert(nvs_flash_init == ESP_OK);
        }
        else
        {
            assert(firstInitResult == ESP_OK);
        }
    }
    nvsFlashInitialized = true;
}
