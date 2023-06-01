module main;

import idf.stdio : printf, putchar;
import idf.freertos : vTaskDelay, msecs;
import idf.string : CStringOf;

import std.algorithm : each; // Only templates can be imported, and even then they often don't compile


@safe @nogc nothrow:

extern(C) void app_main()
{
    int i = 0;
    printf("Hello, dlang says: i = %d\r\n", i);
    "Another line\r\n".each!putchar;

    while (1)
    {
        printf("%d %s\r\n", ++i, CStringOf!"seconds have passsed");
        vTaskDelay(1000.msecs);
    }
}

void d_mangled_func()
{
    scope(exit) printf("d_mangled_func exit");
    printf("d_mangled_func entry");
}
