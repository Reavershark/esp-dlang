module app.framebuffer;

import app.color : Color;
import app.video_timings : VideoTimings;

import idfd.util;

import idf.heap.caps : MALLOC_CAP_DMA;

struct FrameBuffer
{
    private const VideoTimings* m_vt;
    private Color*[] m_lineBuffers;

    this(const VideoTimings* vt)
    {
        m_vt = vt;
        m_lineBuffers = dallocArray!(Color*)(m_vt.v.total);
        foreach (ref Color* lineBuffer; m_lineBuffers)
            lineBuffer = dallocArrayCaps!Color(m_vt.h.total, MALLOC_CAP_DMA).ptr;

        fullClear;
    }

    void fullClear()
    {
        enum Color RED = 1 << 0;
        enum Color GREEN = 1 << 1;
        enum Color BLUE = 1 << 2;
        enum Color WHITE = RED | GREEN | BLUE;
        enum Color BLACK = 0;

        enum Color HSYNC_ON = 0;
        enum Color HSYNC_OFF = 1 << 6;
        enum Color VSYNC_ON = 0;
        enum Color VSYNC_OFF = 1 << 7;

        foreach (y; 0 .. m_vt.v.total)
        {
            Color[] line = m_lineBuffers[y][0 .. m_vt.h.total];

            if (y < m_vt.v.resEnd)
            {
                line[m_vt.h.resStart   .. m_vt.h.resEnd  ] = RED | HSYNC_OFF | VSYNC_OFF;
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

    ~this()
    {
        // dfree(m_fb);
    }

    Color[] getLineWithSync(in uint y) pure
    in (y < m_vt.v.total)
    {
        return m_lineBuffers[y][0 .. m_vt.h.total];
    }

    // Color[] getLine(in uint y) pure
    // in (line < m_height)
    // {
    //     return m_fb[m_vt.h.total * y .. m_vt.h.total * y + ];
    // }

    // Color[] opIndex(in uint y)
    // in (line < m_height)
    // {
    //     return getLine(line);
    // }

    // ref Color opIndex(in uint y, in uint x)
    // in (line < m_height)
    // in (column < m_width)
    // {
    //     return m_fb[m_width * line + column];
    // }
}