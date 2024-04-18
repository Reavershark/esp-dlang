module app.main;

import idfd.tcp : tcp_client;
import idfd.util;
import idfd.wifi_client : simpleWifiInit;

import idf.freertos : vTaskDelay;
import idf.stdio : printf;

// dfmt off
@safe:

extern(C) void app_main()
{
    printf("Hello world!\n");

    simpleWifiInit!("My SSID", "mypassword");

    (() @trusted => tcp_client("10.0.0.10", 1234))();
}
