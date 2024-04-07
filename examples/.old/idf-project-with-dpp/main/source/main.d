module main;

import idf.stdio : printf, putchar;
import idf.freertos : vTaskDelay, msecs;
import idf.esp.err : ESP_OK;
import idf.esp.wifi : esp_wifi_start;

import utils.string : CStringOf;

import std.algorithm : each; // Only templates can be imported, and even then they often don't compile

@safe @nogc nothrow:

extern(C) void app_main()
{
    int i = 0;
    printf("Hello, dlang says: i = %d\r\n", i);
    "Another line\r\n".each!putchar;

    //() @trusted {
    //    if (esp_wifi_start != ESP_OK) assert(0);//fail("msg");
    //}();

    while (1)
    {
        printf("%d %s\r\n", ++i, CStringOf!"seconds have passsed");
        vTaskDelay(1000.msecs);
    }
}

void d_mangled_func()
{
    scope(exit) printf("d_mangled_func exit\r\n");
    printf("d_mangled_func entry\r\n");
}
