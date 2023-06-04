module idf.freertos;

public import idf.freertos.includes_dpp;

@safe @nogc nothrow:

extern(C) @trusted
{
    void vTaskDelay(const(uint));
}

pure
{
    uint msecs(uint duration_in_ms)
        => duration_in_ms / portTICK_PERIOD_MS;

    uint seconds(uint duration_in_seconds)
        => msecs(duration_in_seconds * 1000);

    uint minutes(uint duration_in_minutes)
        => seconds(duration_in_minutes * 60);

    uint hours(uint duration_in_hours)
    in (duration_in_hours <= 50 * 24, "The provided duration would overflow")
        => minutes(duration_in_hours * 60);

    uint days(uint duration_in_days)
    in (duration_in_days <= 50, "The provided duration would overflow")
        => hours(duration_in_days * 24);

    /**
     * This indicates whether the argument function can give a less accurate result than expected due to the "CONFIG_FREERTOS_HZ" setting being too low.
     * Example: `enum IsMsecsAcccurate = is_time_func_accurate(&msecs);`
     */
    bool is_time_func_accurate(T)(T func) => func(0) != func(1);
}

