module idfd.nvs_flash;

import idf.nvs_flash;

shared nvsFlashInitialized = false;

void initNvsFlash(bool eraseIfNeeded = true)() @trusted
{
    printf("Initializing NVS Flash...\n"); // LOGI
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
