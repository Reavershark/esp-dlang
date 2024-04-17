module app.framebuffer;

import app.color : Color;
import app.video_timings : VideoTimings;

import idfd.util;

import idf.heap.caps : MALLOC_CAP_DMA;

struct FrameBuffer
{
    private const VideoTimings* m_vt;
    private Color[][] m_lineBuffers;

    this(const VideoTimings* vt)
    {
        m_vt = vt;
        m_lineBuffers = dallocArray!(Color[])(m_vt.v.total);
        foreach (ref Color[] lineBuffer; m_lineBuffers)
            lineBuffer = dallocArrayCaps!Color(m_vt.h.total, MALLOC_CAP_DMA);

        fullClear;
    }

    void fullClear()
    {
        foreach (y; 0 .. m_vt.v.total)
        {
            Color[] line = m_lineBuffers[y][0 .. m_vt.h.total];

            if (y < m_vt.v.resEnd)
            {
                line[m_vt.h.resStart   .. m_vt.h.resEnd  ] = Color.BLACK;
                line[m_vt.h.frontStart .. m_vt.h.frontEnd] = Color.BLANK;
                line[m_vt.h.syncStart  .. m_vt.h.syncEnd ] = Color.BLANK | Color.HSYNC;
                line[m_vt.h.backStart  .. m_vt.h.backEnd ] = Color.BLANK;
            }
            else
            {
                const bool inVSync = m_vt.v.syncStart <= y && y < m_vt.v.syncEnd;
                const Color vSync = inVSync ? Color.VSYNC : Color.BLANK;
                line[m_vt.h.resStart   .. m_vt.h.resEnd  ] = Color.BLANK | vSync;
                line[m_vt.h.frontStart .. m_vt.h.frontEnd] = Color.BLANK | vSync;
                line[m_vt.h.syncStart  .. m_vt.h.syncEnd ] = Color.BLANK | vSync | Color.HSYNC;
                line[m_vt.h.backStart  .. m_vt.h.backEnd ] = Color.BLANK | vSync;
            }
        }
    }


    ~this()
    {
        foreach(lineBuffer; m_lineBuffers)
            dfree(lineBuffer);
        dfree(m_lineBuffers);
    }

    Color[] getLineWithSync(in uint y) pure
    in (y < m_vt.v.total)
    {
        return m_lineBuffers[m_vt.v.resStart + y][0 .. m_vt.h.total];
    }

    Color[] getLine(in uint y) pure
    in (y < m_vt.v.res)
    {
        return m_lineBuffers[m_vt.v.resStart + y][m_vt.h.resStart .. m_vt.h.resEnd];
    }

    Color[] opIndex(in uint y) pure
    in (y < m_vt.v.res)
    {
        return getLine(y);
    }

    ref Color opIndex(in uint y, in uint x) pure
    in (y < m_vt.v.res)
    in (x < m_vt.h.res)
    {
        return getLine(y)[x ^ 2];
    }

    void fill(Color color) pure
    {
        foreach (y; 0 .. m_vt.v.res)
            getLine(y)[] = color;
    }

    void clear() pure => fill(Color.BLACK);

    void fillIteratingColorsDiagonal(string indexFunc = "x+y")()
    {
        immutable Color[] colors = [
            Color.BLACK, Color.RED, Color.GREEN, Color.BLUE,
            Color.YELLOW, Color.MAGENTA, Color.CYAN, Color.WHITE,
        ];

        foreach (y; 0 .. m_vt.v.res)
            foreach (x; 0 .. m_vt.h.res)
            {
                auto index = mixin(indexFunc);
                this[y][x] = colors[index % colors.length];
            }
    }

    void drawGrayscaleImage(
        in ubyte[] image,
        in Color whiteColor = Color.WHITE,
        in Color blackColor = Color.BLACK,
    )
    in(image.length == m_vt.v.res * m_vt.h.res)
    {
        foreach (y; 0 .. m_vt.v.res)
            foreach (x; 0 .. m_vt.h.res)
            {
                ubyte imageByte = image[m_vt.h.res * y + x];
                this[y, x] = imageByte > 0x80 ? whiteColor : blackColor;
            }
    }
}