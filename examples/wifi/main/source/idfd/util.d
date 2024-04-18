module idfd.util;

import idf.stdlib : free, malloc;

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

void dfree(T)(T* t) @trusted
{
    free(cast(void*) t);
}

void dfree(T)(T[] t) @trusted
{
    free(cast(void*) t.ptr);
}

T* move(T)(ref T* val)
{
    T* tmp = val;
    val = null;
    return tmp;
}

T[] move(T)(ref T[] slice)
{
    T[] tmp = slice;
    slice = [];
    return tmp;
}

struct UniqueHeapPtr(T)
{
    private T* m_ptr;

    @disable this();

    this(T* ptr) pure
    {
        m_ptr = ptr;
    }

    ~this()
    {
        dfree(m_ptr);
    }

    static typeof(this) create(CtorArgs...)(CtorArgs ctorArgs)
    {
        T* ptr = dalloc!T;
        *ptr = T(ctorArgs);
        return typeof(this)(ptr);
    }

    bool empty() pure const => m_ptr is null;

    void reset()
    in (!empty)
    {
        dfree(m_ptr);
        m_ptr = null;
    }

    T* get() pure => m_ptr;
}

struct UniqueHeapArray(T)
{
    private T[] m_arr;

    @disable this();

    this(T[] arr) pure
    {
        m_arr = arr;
    }

    ~this()
    {
        static if (is(T == struct))
            foreach (el; m_arr)
                destroy(el);
        dfree(m_arr);
    }

    static typeof(this) create(size_t length, CtorArgs...)(CtorArgs ctorArgs)
    {
        T[] arr = dallocArray!T(length);
        foreach (ref el; arr)
            el = T(ctorArgs);
        return typeof(this)(move(arr));
    }

    bool empty() pure const => m_arr is [];

    void reset()
    in (!empty)
    {
        dfree(m_arr);
        m_arr = [];
    }

    T[] get() pure => m_arr;
}

enum string stringzOf(string S) = (S ~ '\0');
enum immutable(char)* stringzPtrOf(string S) = (S ~ '\0').ptr;
