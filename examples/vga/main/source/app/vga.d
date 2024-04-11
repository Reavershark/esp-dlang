module app.vga;

import app.color : Color;
import app.util : dallocArray, dallocArrayCaps;
import app.i2s_manager : I2SManager;
import app.video_timings : VideoTimings;

import idf.esp_rom.lldesc : lldesc_t;
import idf.heap.caps : MALLOC_CAP_DMA;
import idf.stdio : printf;

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
    DMALineBufferRing dmaLineBufferRing;
    I2SManager i2sManager;

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
        dmaLineBufferRing = DMALineBufferRing(vt, &frameBuffers[0]);

        int[8] pinMap = [
            pins.red, pins.green, pins.blue, -1, // bits 0-3
            -1, -1, pins.hSync, pins.vSync       // bits 4-7
        ];
        i2sManager = I2SManager(i2sIndex, pinMap[], vt.pixelClock, dmaLineBufferRing.firstDescriptor);
    }

private:
    void initFrameBuffers()
    {
        foreach (ref fb; frameBuffers)
        {
            fb = FrameBuffer.create(vt.activeWidth, vt.activeHeight);
            fb.fill(0xC1);
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

struct DMALineBufferRing
{
// Instance fields
private:
    const VideoTimings* vt;
    FrameBuffer* frameBuffer;

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
    )
    in (vt !is null)
    in (frameBuffer !is null)
    {
        this.vt = vt;
        this.frameBuffer = frameBuffer;

        initLineBuffers;
        initDescriptorRing;
        assignBuffersToDescriptors;
    }

private:
    void initLineBuffers()
    {
        assert(vt.inactiveWidth % 4 == 0);
        inactiveBuffer = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        vSyncInactiveBuffer = dallocArrayCaps!ubyte(vt.inactiveWidth, MALLOC_CAP_DMA);
        blankActiveBuffer = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);
        vSyncActiveBuffer = dallocArrayCaps!ubyte(vt.activeWidth, MALLOC_CAP_DMA);

        foreach (uint i; 0 .. vt.inactiveWidth)
        {
            if (vt.h.front <= i && i < vt.h.front + vt.h.sync)
            {
                vSyncInactiveBuffer[i ^ 2] = 0;
                inactiveBuffer     [i ^ 2] = 0x80;
            }
            else
            {
                vSyncInactiveBuffer[i ^ 2] = 0x40;
                inactiveBuffer     [i ^ 2] = 0xC0;
            }
        }
        foreach (i; 0 .. vt.activeWidth)
        {
            blankActiveBuffer[i ^ 2] = 0xC0;
            vSyncActiveBuffer[i ^ 2] = 0x40;
        }
    }

    void initDescriptorRing()
    {
        descriptors = dallocArrayCaps!lldesc_t(vt.v.total * 2, MALLOC_CAP_DMA);
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

struct FrameBuffer
{
// Instance fields
private:
    uint width, height;
    Color[][] lines;

// Static methods
public:
    static FrameBuffer create(const uint width, const uint height)
    in (width > 0 && height > 0)
    {
        FrameBuffer fb = {
            width: width,
            height: height,
            lines: dallocArray!(Color[])(height),
        };
        foreach (ref Color[] line; fb.lines)
            line = dallocArrayCaps!(Color)(width, MALLOC_CAP_DMA);

        return fb;
    }

// Instance methods
public:
    void fill(in Color fillColor)
    {
        foreach (ref line; lines)
            foreach (i; 0 .. line.length)
                line[i] = fillColor;
    }

    inout(Color[]) getLine(in uint line) inout
    in (line < height)
    {
        return lines[line];
    }
}
