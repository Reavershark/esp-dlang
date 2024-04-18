module app.dma_descriptor_ring;

import idfd.util;

import idf.esp_rom.lldesc : lldesc_t;
import idf.heap.caps : MALLOC_CAP_DMA;

@safe:
// dfmt off

struct DMADescriptorRing
{
    private lldesc_t[] m_descriptors;

    this(in size_t descriptorCount)
    {
        initDescriptors(descriptorCount);
    }

    private void initDescriptors(size_t descriptorCount)
    {
        // Alloc structs
        m_descriptors = dallocArrayCaps!lldesc_t(descriptorCount, MALLOC_CAP_DMA);
        // Init structs
        foreach (ref descriptor; m_descriptors)
        {
            descriptor.length = 0;
            descriptor.size = 0;
            descriptor.sosf = 0;
            descriptor.eof = 1;
            descriptor.owner = 1;
            descriptor.buf = null;
            descriptor.offset = 0;
            descriptor.empty = 0;
            (() @trusted => descriptor.qe.stqe_next = null)();
        }
        // Link them in a ring
        foreach (i; 0 .. m_descriptors.length)
        {
            lldesc_t* next = &m_descriptors[(i + 1) % m_descriptors.length];
            (() @trusted => m_descriptors[i].qe.stqe_next = next)();
        }
    }

    void setBuffers(ubyte[][] buffers) pure
    in (buffers.length == m_descriptors.length)
    {
        foreach (i, ref descriptor; m_descriptors)
        {
            ubyte[] buf = buffers[i];
            descriptor.length = buf.length;
            descriptor.size = buf.length;
            descriptor.buf = cast(ubyte*) &buf[0];
        }
    }

    lldesc_t* firstDescriptor() pure => &m_descriptors[0];
}
