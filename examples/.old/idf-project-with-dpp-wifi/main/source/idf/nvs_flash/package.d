module idf.nvs_flash;

public import idf.nvs_flash.includes_dpp;

@safe @nogc nothrow:

import idf.esp.log : ESP_LOGI;

bool nvsFlashInitialized = false;

void initNvsFlash(bool eraseIfNeeded = true)() @trusted
{
    ESP_LOGI!"Initializing NVS Flash...";
    static if (!eraseIfNeeded)
    {
        assert(nvs_flash_init == ESP_OK);
    }
    else
    {
        esp_err_t first_init_result = nvs_flash_init;
        if (first_init_result == ESP_ERR_NVS_NO_FREE_PAGES || first_init_result == ESP_ERR_NVS_NEW_VERSION_FOUND)
        {
          assert(nvs_flash_erase == ESP_OK);
          assert(nvs_flash_init == ESP_OK);
        }
        else
        {
            assert(first_init_result == ESP_OK);
        }
    }

    nvsFlashInitialized = true;
}
