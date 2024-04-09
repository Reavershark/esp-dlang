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
