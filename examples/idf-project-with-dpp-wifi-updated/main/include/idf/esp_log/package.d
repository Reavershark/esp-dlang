module idf.esp_log;

public import idf.esp_log.esp_log_dpp;

///                                            ///
// Fix broken LOG_COLOR macro and level defines //
///                                            ///

static if (CONFIG_LOG_COLORS)
{
    enum LOG_COLOR(string color) = "\033[0;" ~ color ~ "m";
    enum LOG_COLOR_E = LOG_COLOR!LOG_COLOR_RED;
    enum LOG_COLOR_W = LOG_COLOR!LOG_COLOR_BROWN;
    enum LOG_COLOR_I = LOG_COLOR!LOG_COLOR_GREEN;
    enum LOG_COLOR_V = "";
    enum LOG_COLOR_D = "";
}
else
{
    enum LOG_COLOR_E = "";
    enum LOG_COLOR_W = "";
    enum LOG_COLOR_I = "";
    enum LOG_COLOR_V = "";
    enum LOG_COLOR_D = "";
}

///                                        ///
// Implement broken log macros as templates //
///                                        ///

import idf._internal.helper_templates : stringzPtrOf;

private template EspLogFuncTemplateImpl(string LogLevelString)
{
    static assert(LogLevelString.length > 0);

    alias LogLevelAsEnumMember = mixin("ESP_LOG_" ~ LogLevelString);

    public void ESP_LOGX(string Format, string Tag = "default", Args...)(Args args)
    {
        // Only generate a function body if the config allows this log level to be printed
        static if (LogLevelAsEnumMember <= LOG_LOCAL_LEVEL)
        {
            alias LogLevelColor = mixin("LOG_COLOR_" ~ LogLevelString[0]);
            enum string OuterFormat = LogLevelColor ~ "E (%u) %s " ~ LOG_RESET_COLOR ~ "\n";
            esp_log_write(LogLevelAsEnumMember, stringzPtrOf!Tag, OuterFormat, esp_log_timestamp(), stringzPtrOf!Tag, args);
        }
    }

    alias EspLogFuncTemplateImpl = ESP_LOGX;
}

alias ESP_LOGE = EspLogFuncTemplateImpl!"ERROR";
alias ESP_LOGW = EspLogFuncTemplateImpl!"WARN";
alias ESP_LOGI = EspLogFuncTemplateImpl!"INFO";
alias ESP_LOGD = EspLogFuncTemplateImpl!"DEBUG";
alias ESP_LOGV = EspLogFuncTemplateImpl!"VERBOSE";
