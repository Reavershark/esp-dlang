module idfd.freertos;

import idf.freertos;

import idfd.util.string : capitalized;

@safe:

extern(C) @trusted
{
    void vTaskDelay(const(uint));
}

pure
{
    uint msecs(uint durationInMs)
        => durationInMs / portTICK_PERIOD_MS;

    uint seconds(uint durationInSeconds)
        => msecs(durationInSeconds * 1000);

    uint minutes(uint durationInMinutes)
        => seconds(durationInMinutes * 60);

    uint hours(uint durationInHours)
    in (durationInHours <= 50 * 24, "The provided duration would overflow")
        => minutes(durationInHours * 60);

    uint days(uint durationInDays)
    in (durationInDays <= 50, "The provided duration would overflow")
        => hours(durationInDays * 24);

    /**
     * This indicates whether the argument function can give a less accurate result than expected due to the "CONFIG_FREERTOS_HZ" setting being too low.
     * Example: `enum IsMsecsAcccurate = isTimeFuncAccurate(&msecs);`
     */
    bool isTimeFuncAccurate(T)(T func) => func(0) != func(1);

    // Emits IsMsecsAcccurate, IsSecondsAccurate, ...
    static foreach(string timeFunc; ["msecs", "seconds", "minutes", "hours", "days"])
        mixin("enum bool Is" ~ capitalized!timeFunc ~ "Accurate = isTimeFuncAccurate(&" ~ timeFunc ~ ");");
}
