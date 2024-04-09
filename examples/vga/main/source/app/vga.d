module app.vga;

import app.color;
import app.util;
import app.video_timings;

import idf.esp_hw_support.esp_private.periph_ctrl : periph_module_enable;
import idf.esp_rom.lldesc : lldesc_t;
import idf.heap.caps : MALLOC_CAP_DMA;
import idf.soc.i2s_struct : I2S0, I2S1, i2s_dev_t;
import idf.soc.periph_defs : PERIPH_I2S0_MODULE, PERIPH_I2S1_MODULE, periph_module_t;

// dfmt off
@safe:

struct VGA(uint frameBufferCount = 1)
if (frameBufferCount == 1) // Only valid value right now
{
// Static fields
private:
    static immutable(periph_module_t)[] i2sPeripheralModules = [
        PERIPH_I2S0_MODULE,
        PERIPH_I2S1_MODULE
    ];
    static immutable(i2s_dev_t)*[] i2sDevices = [
        &I2S0,
        &I2S1
    ];
    static assert(i2sPeripheralModules.length == i2sDevices.length);

// Instance fields
private:
    const VideoTimings* vt;
    const VGAPins pins;
    const uint i2sModuleIndex;

    FrameBuffer[frameBufferCount] frameBuffers;
    SyncStatus syncStatus;
    DMALineBufferRing dmaLineBufferRing;

    uint currentLine = 0;

// Instance methods
public:
    this(
        const VideoTimings* vt,
        const VGAPins pins,
        const uint i2sModuleIndex = 1, // Only module 1 can output in 8-bit mode
    )
    in (vt !is null)
    in (i2sModuleIndex < i2sPeripheralModules.length)
    {
        this.vt = vt;
        this.pins = pins;
        this.i2sDeviceIndex = i2sDeviceIndex;

        (() @trusted => periph_module_enable(i2sPeripheralModules[i2sModuleIndex]))();

        initFrameBuffers;
        syncStatus = SyncStatus(vt);
        dmaLineBufferRing = DMALineBufferRing(vt, &frameBuffers[0], &syncStatus);

        initParallelOutputMode(pinMap, mode.pixelClock, bitCount, clockPin);

        i2s_dev_t* i2s = i2sDevices[i2sDeviceIndex];
        reset();
        i2s.lc_conf.val = I2S_OUT_DATA_BURST_EN | I2S_OUTDSCR_BURST_EN;
        dmaBufferDescriptorActive = 0;
        i2s.out_link.addr = (uint32_t) firstDescriptorAddress();
        i2s.out_link.start = 1;
        i2s.conf.tx_start = 1;
    }

private:
    void initFrameBuffers()
    {
        foreach (ref fb; frameBuffers)
        {
            fb = FrameBuffer.create(vt.activeWidth, vt.activeHeight);
            fb.fill(0);
        }
    }
}

struct VGAPins
{
// Instance fields
public:
    int red, green, blue, hSync, vSync;
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
}
