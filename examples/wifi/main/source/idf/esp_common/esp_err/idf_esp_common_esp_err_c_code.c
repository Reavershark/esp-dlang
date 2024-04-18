#include "esp_err.h"

void ESP_ERROR_CHECK_CFunc(esp_err_t err)
{
    ESP_ERROR_CHECK(err);
}