module app.main;

import app.color : Color;
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

extern(C) void d_main(
    FinishClockSetupCFuncType finishClockSetupCFunc,
    StartTransmittingCFuncType startTransmittingCFunc
)
{
    {
        static import idfd.signalio.i2s;
        idfd.signalio.i2s.finishClockSetupCFunc = finishClockSetupCFunc;
        idfd.signalio.i2s.startTransmittingCFunc = startTransmittingCFunc;
    }

    const VideoTimings* vt = &videoTimings320x480;

    FrameBuffer frameBuffer = FrameBuffer(vt);

    lldesc_t[] descriptors = dallocArrayCaps!lldesc_t(vt.v.total, MALLOC_CAP_DMA);
    for (int i = 0; i < descriptors.length; i++)
    {
        descriptors[i].length = 0;
        descriptors[i].size = 0;
        descriptors[i].owner = 1;
        descriptors[i].sosf = 0;
        descriptors[i].buf = null;
        descriptors[i].offset = 0;
        descriptors[i].empty = 0;
        descriptors[i].eof = 1;
        descriptors[i].qe.stqe_next = null;
    }

    for (int i = 0; i < descriptors.length; i++)
        descriptors[i].qe.stqe_next = &descriptors[(i + 1) % descriptors.length];

    void setDescriptorBuffer(ref lldesc_t descriptor, ubyte[] buffer)
    {
        descriptor.length = buffer.length;
        descriptor.size = buffer.length;
        descriptor.buf = cast(ubyte*) &buffer[0];
    }

    foreach (i, ref descriptor; descriptors)
        setDescriptorBuffer(descriptor, frameBuffer.getLineWithSync(i));

    I2SSignalGenerator signalGenerator = I2SSignalGenerator(
        i2sIndex: 1,
        bitCount: 8,
        freq: vt.pixelClock,
    );

    Signal[] signals = signalGenerator.getSignals;
    scope(exit) dfree(signals);
    assert(signals.length == 8);
    route(from: signals[0], to: GPIOPin(14)); // Red
    route(from: signals[1], to: GPIOPin(27)); // Green
    route(from: signals[2], to: GPIOPin(16)); // Blue
    route(from: signals[6], to: GPIOPin(25)); // HSync
    route(from: signals[7], to: GPIOPin(26)); // VSync

    immutable string zeusImageStr = import("zeus.raw");
    immutable ubyte[] zeusImage = cast(immutable ubyte[]) zeusImageStr;
    assert(zeusImage.length == vt.v.res * vt.h.res);
    foreach (y; 0 .. vt.v.res)
        foreach (x; 0 .. vt.h.res)
        {
            ubyte imageByte = zeusImageStr[vt.h.res * y + x];
            frameBuffer[y, x] = imageByte > 0x80 ? FrameBuffer.YELLOW : FrameBuffer.BLACK;
        }

    signalGenerator.startTransmitting(&descriptors[0]);

    while (true)
    {
        vTaskSuspend(null);
    }
}
