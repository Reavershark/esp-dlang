module main;

import stdio_dpp : putchar;

import std.algorithm : each; // Only templates can be imported, and even then they often don't compile

extern(C) int printf(scope const char* fmt, scope const ...);

extern(C) void app_main()
{
    int i = 0;
    printf("Hello, dlang says: i = %d\r\n", i);
    "Another line\r\n".each!putchar;
}
