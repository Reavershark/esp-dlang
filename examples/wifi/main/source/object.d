module object;

@safe nothrow @nogc:

alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*) 0 - cast(void*) 0);

alias noreturn = typeof(*null);

alias string = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

template imported(string moduleName)
{
    mixin("import imported = " ~ moduleName ~ ";");
}

void destroy(bool initialize = true, T)(ref T obj)
if (is(T == struct))
{
    import core.internal.destruction : destructRecurse;

    destructRecurse(obj);

    static if (initialize)
    {
        import core.internal.lifetime : emplaceInitializer;
        emplaceInitializer(obj); // emplace T.init
    }
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj)
if (__traits(isStaticArray, T))
{
    foreach_reverse (ref e; obj[])
        destroy!initialize(e);
}

/// ditto
void destroy(bool initialize = true, T)(ref T obj)
if (!is(T == struct) && !is(T == interface) && !is(T == class) && !__traits(isStaticArray, T))
{
    static if (initialize)
        obj = T.init;
}

/**
 * The compiler lowers expressions of `cast(TTo[])TFrom[]` to
 * this implementation. Note that this does not detect alignment problems.
 * 
 * Params:
 *     from = the array to reinterpret-cast
 * 
 * Returns:
 *     `from` reinterpreted as `TTo[]`
 */
TTo[] __ArrayCast(TFrom, TTo)(return scope TFrom[] from) pure @trusted
{
    const fromLengthBytes = from.length * TFrom.sizeof;
    if ((fromLengthBytes % TTo.sizeof) != 0)
        assert(false);

    struct RawSlice
    {
        size_t length;
        void* ptr;
    }

    RawSlice* rawSlice = cast(RawSlice*) &from;
    rawSlice.length = fromLengthBytes / TTo.sizeof;
    return *(cast(TTo[]*) rawSlice);
}

extern(C) void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz) @trusted
{
    import ldc.intrinsics : llvm_memcpy;
    llvm_memcpy!size_t(dst, src, dstlen * elemsz, 0);
}
