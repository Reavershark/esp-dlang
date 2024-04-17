module app.framebuffer;

import app.color : Color;
import app.video_timings : VideoTimings;

import idfd.util;

import idf.heap.caps : MALLOC_CAP_DMA;

struct FrameBuffer
{
    enum Color BLACK = 0;
    enum Color RED = 1 << 0;
    enum Color GREEN = 1 << 1;
    enum Color BLUE = 1 << 2;
    enum Color YELLOW = RED | GREEN;
    enum Color MAGENTA = RED | BLUE;
    enum Color CYAN = GREEN | BLUE;
    enum Color WHITE = RED | GREEN | BLUE;

    enum Color HSYNC_OFF = 0;
    enum Color HSYNC_ON = 1 << 6;
    enum Color VSYNC_OFF = 0;
    enum Color VSYNC_ON = 1 << 7;

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
                line[m_vt.h.resStart   .. m_vt.h.resEnd  ] = BLACK | HSYNC_OFF | VSYNC_OFF;
                line[m_vt.h.frontStart .. m_vt.h.frontEnd] = BLACK | HSYNC_OFF | VSYNC_OFF;
                line[m_vt.h.syncStart  .. m_vt.h.syncEnd ] = BLACK | HSYNC_ON  | VSYNC_OFF;
                line[m_vt.h.backStart  .. m_vt.h.backEnd ] = BLACK | HSYNC_OFF | VSYNC_OFF;
            }
            else
            {
                const bool inVSync = m_vt.v.syncStart <= y && y < m_vt.v.syncEnd;
                line[m_vt.h.resStart   .. m_vt.h.resEnd  ] = BLACK | HSYNC_OFF | (inVSync ? VSYNC_ON : VSYNC_OFF);
                line[m_vt.h.frontStart .. m_vt.h.frontEnd] = BLACK | HSYNC_OFF | (inVSync ? VSYNC_ON : VSYNC_OFF);
                line[m_vt.h.syncStart  .. m_vt.h.syncEnd ] = BLACK | HSYNC_ON  | (inVSync ? VSYNC_ON : VSYNC_OFF);
                line[m_vt.h.backStart  .. m_vt.h.backEnd ] = BLACK | HSYNC_OFF | (inVSync ? VSYNC_ON : VSYNC_OFF);
            }
        }
    }

    void fill(Color color) pure
    {
        foreach (y; 0 .. m_vt.v.res)
            getLine(y)[] = color | VSYNC_OFF | HSYNC_OFF;
    }

    void fillIteratingColorsDiagonal(string indexFunc = "x+y")()
    {
        immutable Color[] colors = [
            BLACK, RED, GREEN, BLUE, YELLOW, MAGENTA, CYAN, WHITE
        ];

        foreach (y; 0 .. m_vt.v.res)
            foreach (x; 0 .. m_vt.h.res)
            {
                auto index = mixin(indexFunc);
                this[y][x] = colors[index % colors.length];
            }
    }

    void clear() pure => fill(BLACK);

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

    ref Color opIndexAssign(in Color color, in uint y, in uint x)
    {
        return opIndex(y, x) = color | HSYNC_OFF | VSYNC_OFF;
    }

    // ref Color opIndex(in uint y, in uint x)
    // in (line < m_height)
    // in (column < m_width)
    // {
    //     return m_fb[m_width * line + column];
    // }
}