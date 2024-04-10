module app.vga;

import app.color : Color;
import app.util : dallocArray, dallocArrayCaps;
import app.i2s_manager : I2SManager;
import app.video_timings : VideoTimings;

import idf.esp_rom.lldesc : lldesc_t;
import idf.heap.caps : MALLOC_CAP_DMA;

// dfmt off
@safe:

struct VGA(uint frameBufferCount = 1)
if (frameBufferCount == 1) // Only valid value right now
{
// Instance fields
private:
    const VideoTimings* vt;
    const VGAPins pins;

    FrameBuffer[frameBufferCount] frameBuffers;
    SyncStatus syncStatus;
    DMALineBufferRing dmaLineBufferRing;
    I2SManager i2sManager;

    uint currentLine = 0;

// Instance methods
public:
    this(
        const VideoTimings* vt,
        const VGAPins pins,
        const uint i2sIndex = 1, // Only peripheral 1 can output in 8-bit mode
    )
    in (vt !is null)
    {
        this.vt = vt;
        this.pins = pins;

        initFrameBuffers;
        syncStatus = SyncStatus(vt);
        dmaLineBufferRing = DMALineBufferRing(vt, &frameBuffers[0], &syncStatus);

        int[] pinMap = [
            pins.red, pins.green, pins.blue, -1, // bits 0-3
            -1, -1, pins.hSync, pins.vSync       // bits 4-7
        ];
        i2sManager = I2SManager(i2sIndex, pinMap, vt.pixelClock, dmaLineBufferRing.firstDescriptor);
    }

private:
    void initFrameBuffers()
    {
        foreach (ref fb; frameBuffers)
        {
            fb = FrameBuffer.create(vt.activeWidth, vt.activeHeight);
            fb.fill(1);
        }
    }
}

struct VGAPins
{
// Instance fields
public:
    int red   = -1;
    int green = -1;
    int blue  = -1;
    int hSync = -1;
    int vSync = -1;
}

struct FrameBuffer
{
// Instance fields
private:
    uint width, height;
    Color[] arr;

// Static methods
public:
    static FrameBuffer create(const uint width, const uint height)
    in (width > 0 && height > 0)
    {
        FrameBuffer fb = {
            width: width,
            height: height,
            arr: dallocArray!Color(width * height),
        };
        return fb;
    }

// Instance methods
public:
    void fill(in Color fillColor) pure
    {
        foreach (ref color; arr)
            color = fillColor;
    }

    inout(Color[]) getLine(in uint line) inout
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
    Color vsyncBitI;
    Color hsyncBitI;
    Color vsyncBit;
    Color hsyncBit;
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
// Instance fields
private:
    const VideoTimings* vt;
    FrameBuffer* frameBuffer;
    const SyncStatus* syncStatus;

    lldesc_t[] descriptors;
    ubyte[] inactiveBuffer;
    ubyte[] vSyncInactiveBuffer;
    ubyte[] blankActiveBuffer;
    ubyte[] vSyncActiveBuffer;
    size_t activeDescriptor;

// Instance methods
public:
    this(
        const VideoTimings* vt,
        FrameBuffer* frameBuffer,
        const SyncStatus* syncStatus
    )
    in (vt !is null)
    in (frameBuffer !is null)
    {
        this.vt = vt;
        this.frameBuffer = frameBuffer;

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
            (() @trusted { desc.qe.stqe_next = &descriptors[(i + 1) % descriptors.length]; }());
        }
    }

    void initLineBuffers()
    {
        assert(vt.inactiveWidth % 4 == 0);
        inactiveBuffer = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        vSyncInactiveBuffer = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        blankActiveBuffer = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);
        vSyncActiveBuffer = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);

        foreach (i; 0 .. vt.inactiveWidth)
        {
            bool inHsync = (vt.h.front <= i && i < vt.h.front + vt.h.sync);
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
        void setDescriptorBuffer(ref lldesc_t desc, ubyte[] buffer) pure @safe
        {
            desc.length = buffer.length;
            desc.size = buffer.length;
            desc.buf = &buffer[0];
        }

        int d = 0;
        foreach (i; 0 .. vt.v.front)
        {
            setDescriptorBuffer(descriptors[d++], inactiveBuffer);
            setDescriptorBuffer(descriptors[d++], blankActiveBuffer);
        }
        foreach (i; 0 .. vt.v.sync)
        {
            setDescriptorBuffer(descriptors[d++], vSyncInactiveBuffer);
            setDescriptorBuffer(descriptors[d++], vSyncActiveBuffer);
        }
        foreach (i; 0 .. vt.v.back)
        {
            setDescriptorBuffer(descriptors[d++], inactiveBuffer);
            setDescriptorBuffer(descriptors[d++], blankActiveBuffer);
        }
        foreach (i; 0 .. vt.v.res)
        {
            setDescriptorBuffer(descriptors[d++], inactiveBuffer);
            setDescriptorBuffer(descriptors[d++], frameBuffer.getLine(i / vt.vDiv));
        }
        assert(d == descriptors.length);
    }

public:
    inout(lldesc_t)* firstDescriptor() pure inout
    in (descriptors.length)
    {
        return &descriptors[0];
    }
}
