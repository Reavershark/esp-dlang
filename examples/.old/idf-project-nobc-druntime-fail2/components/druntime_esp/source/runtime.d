/// Mini runtime for D -betterC
module runtime;

///                           ///
// Required external functions //
///                           ///
private extern(C) void* malloc(size_t size) nothrow @nogc;
private extern(C) void* memcpy(void* dest, const(void)* src, size_t n) nothrow @nogc;


///                  ///
// Integer allocation //
///                  ///

private class TypeInfoGeneric(T, BaseClass = TypeInfo) : BaseClass
{
    const: nothrow: pure: @trusted:

    static foreach(Other; Others)
    {
        static assert(T.sizeof == Other.sizeof);
    }

    override @property size_t tsize() => T.sizeof;
}

//private class TypeInfoGeneric(T, Others...) : TypeInfo
//{
//    const: nothrow: pure: @trusted:
//
//    static foreach(Other; Others)
//    {
//        static assert(T.sizeof == Other.sizeof);
//    }
//
//    override @property size_t tsize() => T.sizeof;
//}

string MakeTypeInfoGeneric(string id, T, ReuseFromT = T) =
{
    static if (ReuseFromT == T)
    {

    }



    class TypeInfoGeneric(T, BaseClass = TypeInfo) : BaseClass
    {
        const: nothrow: pure: @trusted:
    
        static foreach(Other; Others)
        {
            static assert(T.sizeof == Other.sizeof);
        }
    
        override @property size_t tsize() => T.sizeof;
    }

    return TypeInfoGeneric
}();

class TypeInfo_h : TypeInfoGeneric!ubyte {}
class TypeInfo_b : TypeInfoGeneric!(bool, ubyte) {}
class TypeInfo_g : TypeInfoGeneric!(byte, ubyte) {}
class TypeInfo_a : TypeInfoGeneric!(char, ubyte) {}
class TypeInfo_t : TypeInfoGeneric!ushort {}
class TypeInfo_s : TypeInfoGeneric!(short, ushort) {}
class TypeInfo_u : TypeInfoGeneric!(wchar, ushort) {}
class TypeInfo_w : TypeInfoGeneric!(dchar, uint) {}
class TypeInfo_k : TypeInfoGeneric!uint {}
class TypeInfo_i : TypeInfoGeneric!(int, uint) {}
class TypeInfo_m : TypeInfoGeneric!ulong {}
class TypeInfo_l : TypeInfoGeneric!(long, ulong) {}
static if (is(cent)) class TypeInfo_zi : TypeInfoGeneric!cent {}
static if (is(ucent)) class TypeInfo_zk : TypeInfoGeneric!ucent {}

extern(C) void* _d_allocmemoryT(TypeInfo ts)
{
    return malloc(ts.tsize);
}


///                        ///
// Integer array allocation //
///                        ///

private class TypeInfoArrayGeneric(T, Others...) : TypeInfo_Array
{
    static foreach(Other; Others)
    {
        static assert(T.sizeof == Other.sizeof);
    }
}

class TypeInfo_Ah : TypeInfoArrayGeneric!ubyte {}
class TypeInfo_Ab : TypeInfoArrayGeneric!(bool, ubyte) {}
class TypeInfo_Ag : TypeInfoArrayGeneric!(byte, ubyte) {}
class TypeInfo_Aa : TypeInfoArrayGeneric!(char, ubyte) {}
class TypeInfo_Axa : TypeInfoArrayGeneric!(const char) {}
class TypeInfo_Aya : TypeInfoArrayGeneric!(immutable char)
{
    // Must override this, otherwise "string" is returned.
    override string toString() const { return "immutable(char)[]"; }
}
class TypeInfo_At : TypeInfoArrayGeneric!ushort {}
class TypeInfo_As : TypeInfoArrayGeneric!(short, ushort) {}
class TypeInfo_Au : TypeInfoArrayGeneric!(wchar, ushort) {}
class TypeInfo_Ak : TypeInfoArrayGeneric!uint {}
class TypeInfo_Ai : TypeInfoArrayGeneric!(int, uint) {}
class TypeInfo_Aw : TypeInfoArrayGeneric!(dchar, uint) {}
class TypeInfo_Am : TypeInfoArrayGeneric!ulong {}
class TypeInfo_Al : TypeInfoArrayGeneric!(long, ulong) {}


///                ///
// Class allocation //
///                ///

extern (C) Object _d_allocclass(const ClassInfo ci) nothrow
{
    return cast(Object) malloc(ci.initializer.length);
}

extern (C) Object _d_newclass(const ClassInfo ci) nothrow
{
    const initializer = ci.initializer;

    void* p = malloc(initializer.length);
    memcpy(p, initializer.ptr, initializer.length);
    return cast(Object) p;
}

/**
 * Attempts to cast Object o to class c.
 * Returns o if successful, null if not.
 */
extern(C) void* _d_dynamic_cast(Object o, ClassInfo c)
{
    assert(false, "_d_dynamic_cast is not implemented");
}


///                         ///
// Dynamic arrays operations //
///                         ///

/// Called for `arr1 ~= arr2`
extern (C) byte[] _d_arrayappendcTX(const TypeInfo ti, ref return scope byte[] px, size_t n)
{
    return [];
}

/// Called for `arr1 ~ arr2`
extern (C) byte[] _d_arraycatT(const TypeInfo ti, byte[] x, byte[] y)
{
    return null;
}


/// Called for `arr1 ~ arr2 ~ arr3 ~ ...`
extern (C) void[] _d_arraycatnTX(const TypeInfo ti, scope byte[][] arrs)
{
    return [];
}


///                             ///
// Exception throwing / handling //
///                             ///

extern(C) void _d_throw_exception(Throwable throwable)
{
}

extern(C) void* __wrap__Unwind_Resume()
{
    return null;
}

extern(C) Throwable _d_eh_enter_catch(void* ptr)
{
    return null;
}

extern(C) __gshared int _d_eh_personality(int, int, ulong, void*, void*)
{
    return 0;
}

extern(C) void _d_assert(string file, uint line)
{
}

extern(C) void _d_assert_msg(string message, string file, uint line)
{
}

///          ///
// ModuleInfo //
///          ///

/// Required for the legacy ModuleInfo discovery mechanism
extern(C) __gshared void* _Dmodule_ref;

/// Required for the new ModuleInfo discovery mechanism
extern(C) immutable void* __start___minfo;
/// ditto
extern(C) immutable void* __stop___minfo;


///
// To sort
///

