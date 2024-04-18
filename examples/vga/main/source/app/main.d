module app.main;

import app.color : Color;
import app.dma_descriptor_ring : DMADescriptorRing;
import app.framebuffer : FrameBuffer;
import app.video_timings : VideoTimings, videoTimings320x480;

import idfd.signalio.gpio : GPIOPin;
import idfd.signalio.i2s : FinishClockSetupCFuncType, I2SSignalGenerator, StartTransmittingCFuncType;
import idfd.signalio.router : route;
import idfd.signalio.signal : Signal;
import idfd.util;

import idf.esp_rom.lldesc : lldesc_t;
import idf.freertos : vTaskDelay, vTaskSuspend;
import idf.heap.caps : MALLOC_CAP_DMA;
import idf.stdio : printf;

// dfmt off
@safe:

extern(C) void d_main()
{
    const VideoTimings* vt = &videoTimings320x480;

    FrameBuffer frameBuffer = FrameBuffer(vt);

    DMADescriptorRing dmaDescriptorRing = DMADescriptorRing(vt.v.total);
    dmaDescriptorRing.setBuffers((() @trusted => cast(ubyte[][]) frameBuffer.linesWithSync)());

    I2SSignalGenerator signalGenerator = I2SSignalGenerator(
        i2sIndex: 1,
        bitCount: 8,
        freq: vt.pixelClock,
    );

    {
        UniqueHeapArray!Signal signals = signalGenerator.getSignals;
        route(from: signals.get[0], to: GPIOPin(14)); // Red
        route(from: signals.get[1], to: GPIOPin(27)); // Green
        route(from: signals.get[2], to: GPIOPin(16)); // Blue
        route(from: signals.get[6], to: GPIOPin(25)); // HSync
        route(from: signals.get[7], to: GPIOPin(26)); // VSync
    }

    immutable ubyte[] zeusImage = cast(immutable ubyte[]) import("zeus.raw");
    frameBuffer.drawGrayscaleImage(zeusImage, Color.YELLOW, Color.BLACK);

    signalGenerator.startTransmitting(dmaDescriptorRing.firstDescriptor);

    printf("Initialization complete");

    while (true)
    {
        (() @trusted => vTaskSuspend(null))();
    }
}
