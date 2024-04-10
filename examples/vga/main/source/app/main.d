module app.main;

import app.vga : VGA, VGAPins;
import app.video_timings : videoTimings320x480;

// dfmt off
@safe:

immutable vt = &videoTimings320x480;
enum pins = VGAPins(
    red:   14,
    green: 27,
    blue:  16,
    hSync: 25,
    vSync: 26
);

extern (C)
void app_main()
{
    auto vga = VGA!()(vt, pins);

    while (true)
    {
    }
}
