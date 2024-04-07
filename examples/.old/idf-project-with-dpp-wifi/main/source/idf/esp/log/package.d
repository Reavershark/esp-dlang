module idf.log;

public import idf.esp.log.includes_dpp;

import utils.string : StringzPtrOf;

@safe @nogc nothrow:

// Implement broken log macros as templates

enum LOG_COLOR(string color) = "\033[0;" ~ color ~ "m";
enum LOG_COLOR_E = LOG_COLOR!LOG_COLOR_RED;
enum LOG_COLOR_W = LOG_COLOR!LOG_COLOR_BROWN;
enum LOG_COLOR_I = LOG_COLOR!LOG_COLOR_GREEN;
enum LOG_COLOR_V = "";
enum LOG_COLOR_D = "";

// Provides ESP_LOGE, ESP_LOGW, ESP_LOGI, ESP_LOGD and ESP_LOGV.
// Signature: `void ESP_LOGX(string format, string tag = "default", Args...)(Args args)`
static foreach(logLevel; ["ERROR", "WARN", "INFO", "DEBUG", "VERBOSE"])
{
    mixin(() {
        assert(logLevel.length > 0);
        char firstLetter = logLevel[0];
        string s;
        s ~= "void ESP_LOG" ~ firstLetter ~ "(string format, string tag = __MODULE__, Args...)(Args args) @trusted\n";
        s ~= "{\n";
        s ~= `    enum string fmt = LOG_COLOR_` ~ firstLetter ~ ` ~ "` ~ firstLetter ~ ` (%u) %s: " ~ format ~ LOG_RESET_COLOR ~ "\n";` ~ "\n";
        s ~= "    enum tagStringzPtr = StringzPtrOf!tag;\n";
        s ~= "    esp_log_write(ESP_LOG_" ~ logLevel ~ ", tagStringzPtr, StringzPtrOf!fmt, esp_log_timestamp, tagStringzPtr, args);\n";
        s ~= "}\n";
        return s;
    }());
}

/*
void ESP_LOGE(string format, string tag = "default", Args...)(Args args)
{
    enum string fmt = LOG_COLOR_E ~ "E (%u) %s " ~ LOG_RESET_COLOR ~ "\n";
    esp_log_write(ESP_LOG_ERROR, tag, fmt, esp_log_timestamp, tag, args);
}

void ESP_LOGW(string format, string tag = "default", Args...)(Args args)
{
    enum string fmt = LOG_COLOR_W ~ "W (%u) %s " ~ LOG_RESET_COLOR ~ "\n";
    esp_log_write(ESP_LOG_WARNING, tag, fmt, esp_log_timestamp, tag, args);
}

void ESP_LOGI(string format, string tag = "default", Args...)(Args args)
{
    enum string fmt = LOG_COLOR_I ~ "I (%u) %s " ~ LOG_RESET_COLOR ~ "\n";
    esp_log_write(ESP_LOG_INFO, tag, fmt, esp_log_timestamp, tag, args);
}

void ESP_LOGV(string format, string tag = "default", Args...)(Args args)
{
    enum string fmt = LOG_COLOR_V ~ "V (%u) %s " ~ LOG_RESET_COLOR ~ "\n";
    esp_log_write(ESP_LOG_VERBOSE, tag, fmt, esp_log_timestamp, tag, args);
}

void ESP_LOGD(string format, string tag = "default", Args...)(Args args)
{
    enum string fmt = LOG_COLOR_D ~ "d (%U) %S " ~ LOG_RESET_COLOR ~ "\n";
    esp_log_write(ESP_LOG_DEBUG, tag, fmt, esp_log_timestamp, tag, args);
}
*/
