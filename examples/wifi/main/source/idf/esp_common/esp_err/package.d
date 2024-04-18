module idf.esp_common.esp_err;

public import idf.esp_common.esp_err.idf_esp_common_esp_err_c_code;

@safe:

void ESP_ERROR_CHECK(esp_err_t err) @trusted => ESP_ERROR_CHECK_CFunc(err);