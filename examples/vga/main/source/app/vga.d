module app.vga;

import app.color;
import app.util;
import app.video_timings;
import std.algorithm.setops;

import idf.esp_hw_support.esp_private.periph_ctrl : periph_module_enable;
import idf.esp_rom.lldesc : lldesc_t;
import idf.heap.caps : MALLOC_CAP_DMA;

@safe:

struct VGA(uint frameBufferCount = 0)
if (frameBufferCount == 0) // Only valid value right now
{
// Instance fields
private:
    const VideoTimings* vt;
    const int redPin;
    const int greenPin;
    const int bluePin;
    const int hsyncPin;
    const int vsyncPin;
    const uint i2sModuleIndex;

    FrameBuffer[frameBufferCount] frameBuffers;
    SyncStatus syncStatus;
    DMALineBufferRing dmaLineBufferRing;

    uint currentLine = 0;

// Instance methods
public:
    this(
        const VideoTimings* vt,
        const int redPin,
        const int greenPin,
        const int bluePin,
        const int hsyncPin,
        const int vsyncPin,
        const uint i2sModuleIndex = 1, // Only 1 can output in 8-bit
    )
    in (vt !is null)
    {
        this.vt = vt;
        this.redPin = redPin;
        this.greenPin = greenPin;
        this.bluePin = bluePin;
        this.hsyncPin = hsyncPin;
        this.vsyncPin = vsyncPin;
        this.i2sModuleIndex = i2sModuleIndex;

        initFrameBuffers;
        syncStatus = SyncStatus(vt);
        dmaLineBufferRing = DMALineBufferRing(vt, frameBuffers[0], i2sModuleIndex);

	    currentLine = 0;
	    initParallelOutputMode(pinMap, mode.pixelClock, bitCount, clockPin);
	    startTX();
    }

private:
    void initFrameBuffers()
    {
        foreach(ref fb; frameBuffers)
        {
            fb = FrameBuffer.create(width, height);
            fb.fill(0);
        }
    }
}

struct FrameBuffer
{
// Instance fields
private:
    const uint width, height;
    Color[] arr;

// Static methods
public:
    static FrameBuffer create(const uint width, const uint height)
    in (width > 0 && height > 0)
    {
        this.width = width;
        this.height = height;
        this.arr = dallocArray!Color(width * height);
    }

// Instance methods
public:
    void fill(in Color fillColor) pure
    {
        foreach (ref color; arr)
            color = fillColor;
    }

    Color[] getLine(in uint line)
    in (line < height)
    {
        return arr[line * width .. line * width + width];
    }
}

struct SyncStatus
{
// Instance fields
public:
    bool vsyncPassed;
    long vsyncBitI;
    long hsyncBitI;
    long vsyncBit;
    long hsyncBit;
    Color sBits;

// Instance methods
public:
    this(in VideoTimings* vt)
    in (vt !is null)
    {
        vsyncPassed = false;
        vsyncBitI = vt.h.polarity ? 0x40 : 0;
        hsyncBitI = vt.v.polarity ? 0x80 : 0;
        vsyncBit = hsyncBitI ^ 0x40;
        hsyncBit = vsyncBitI ^ 0x80;
        sBits = hsyncBitI | vsyncBitI;
    }
}

struct DMALineBufferRing
{
// Nested types
public:
    enum periph_module_t[] i2sModules = [
        PERIPH_I2S0_MODULE,
        PERIPH_I2S1_MODULE
    ];

// Instance fields
private:
    const VideoTimings* vt;
    const FrameBuffer* frameBuffer;
    const SyncStatus* syncStatus;
    lldesc_t[] descriptors;
    ubyte[] inactiveBuffer;
    ubyte[] vSyncInactiveBuffer;
    ubyte[] blankActiveBuffer;
    ubyte[] vSyncActiveBuffer;

// Instance methods
public:
    this(
        const VideoTimings* vt,
        const FrameBuffer* frameBuffer,
        const SyncStatus* syncStatus,
        in uint i2sModuleIndex
    )
    in (vt !is null)
    in (frameBuffer !is null)
    in (i2sModuleIndex < i2sModules.length)
    {
        this.vt = videoTimings;
        this.frameBuffer = frameBuffer;

        periph_module_enable(i2sModules[i2sModuleIndex]);

        initDescriptorRing;
        initLineBuffers;
        assignBuffersToDescriptors;
    }

private:
    void initDescriptorRing()
    {
        descriptors = dallocArray!lldesc_t(vt.v.total * 2);
        foreach (i, ref desc; descriptors)
        {
            desc.length = 0;
            desc.size = 0;
            desc.owner = 1;
            desc.sosf = 0;
            desc.buf = null;
            desc.offset = 0;
            desc.empty = 0;
            desc.eof = 1;
            desc.qe.stqe_next = &descriptors[(i + 1) % descriptors.length];
        }
    }

    void initLineBuffers()
    {
        assert(vt.inactiveWidth % 4 == 0);
        inactiveBuffer      = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        vSyncInactiveBuffer = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        blankActiveBuffer   = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);
        vSyncActiveBuffer   = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);

        foreach (i; 0 .. vt.inactiveWidth)
        {
            bool inHsync = (v.h.front <= i && i < v.h.front + v.h.sync);
            auto hSyncBit = inHsync ? syncStatus.hsyncBit : syncStatus.hsyncBitI;
            inactiveBuffer     [i ^ 2] = hSyncBit | syncStatus.vsyncBitI;
            vSyncInactiveBuffer[i ^ 2] = hSyncBit | syncStatus.vsyncBit;
        }
        foreach (i; 0 .. vt.activeWidth)
        {
            blankActiveBuffer[i ^ 2] = syncStatus.hsyncBitI | syncStatus.vsyncBitI;
            vSyncActiveBuffer[i ^ 2] = syncStatus.hsyncBitI | syncStatus.vsyncBit;
        }
    }

    void assignBuffersToDescriptors()
    {
        void setDescriptorBuffer(ref lldesc_t desc, ubyte[] buffer) pure
        {
            desc.length = buffer.length;
            desc.size = buffer.length;
            desc.buf = buffer.ptr;
        }

        int d = 0;
        foreach(i; 0 .. vt.v.front)
        {
            descriptors[d++].setDescriptorBuffer(inactiveBuffer);
            descriptors[d++].setDescriptorBuffer(blankActiveBuffer);
        }
        foreach(i; 0 .. vt.v.sync)
        {
            descriptors[d++].setDescriptorBuffer(vSyncInactiveBuffer);
            descriptors[d++].setDescriptorBuffer(vSyncActiveBuffer);
        }
        foreach(i; 0 .. vt.v.back)
        {
            descriptors[d++].setDescriptorBuffer(inactiveBuffer);
            descriptors[d++].setDescriptorBuffer(blankActiveBuffer);
        }
        foreach(i; 0 .. vt.v.res)
        {
            descriptors[d++].setDescriptorBuffer(inactiveBuffer);
            descriptors[d++].setDescriptorBuffer(frameBuffer.getLine(i / vt.vDiv));
        }
        assert(d == descriptors.length);
    }
}
