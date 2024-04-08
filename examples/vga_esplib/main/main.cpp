#include <VGA/VGA3Bit.h>
#include <Resources/Font6x8.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

const int redPin   = 14;
const int greenPin = 27;
const int bluePin  = 16;
const int hsyncPin = 25;
const int vsyncPin = 26;

VGA3Bit vga;

extern "C"
void app_main(void)
{
	vga.init(vga.MODE320x240, redPin, greenPin, bluePin, hsyncPin, vsyncPin);
	vga.setFont(Font6x8);
	vga.println("Hello World!");

    while (1)
    {
        vTaskSuspend(NULL);
    }
}
