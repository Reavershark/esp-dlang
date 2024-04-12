module app.util;

import idf.stdlib : malloc;
import idf.heap.caps : heap_caps_malloc;

@safe:

T* dalloc(T)() @trusted
{
    ubyte* ptr = cast(ubyte*) malloc(T.sizeof);
    assert(ptr, "dalloc: malloc failed");
    foreach (ref b; ptr[0 .. T.sizeof])
        b = 0;
    return cast(T*) ptr;
}

T[] dallocArray(T)(size_t length, ubyte initValue = 0) @trusted
{
    ubyte* ptr = cast(ubyte*) malloc(T.sizeof * length);
    assert(ptr, "dallocArray: malloc failed");
    ubyte[] slice = ptr[0 .. T.sizeof * length];
    foreach (ref b; slice)
        b = initValue;
    return cast(T[]) slice;
}

T* dallocCaps(T)(uint capabilities = 0) @trusted
{
    ubyte* ptr = cast(ubyte*) heap_caps_malloc(T.sizeof, capabilities);
    foreach (ref b; ptr[0 .. T.sizeof])
        b = 0;
    return cast(T*) ptr;
}

T[] dallocArrayCaps(T)(size_t length, uint capabilities = 0, ubyte initValue = 0) @trusted
{
    ubyte* ptr = cast(ubyte*) heap_caps_malloc(T.sizeof * length, capabilities);
    ubyte[] slice = ptr[0 .. T.sizeof * length];
    foreach (ref b; slice)
        b = initValue;
    return cast(T[]) slice;
}
