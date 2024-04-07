module object;

public import core.internal.hash : hashOf;

alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*)0 - cast(void*)0);

alias sizediff_t = ptrdiff_t; // For backwards compatibility only.
/**
 * Bottom type.
 * See $(DDSUBLINK spec/type, noreturn).
 */
alias noreturn = typeof(*null);

alias hash_t = size_t; // For backwards compatibility only.
alias equals_t = bool; // For backwards compatibility only.

alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];

bool _xopEquals(in void*, in void*)
{
    throw new Error("TypeInfo.equals is not implemented");
}

bool _xopCmp(in void*, in void*)
{
    throw new Error("TypeInfo.compare is not implemented");
}

/**
 * All D class objects inherit from Object.
 */
class Object
{
    /**
     * Convert Object to a human readable string.
     */
    string toString()
    {
        return typeid(this).name;
    }

    /**
     * Compute hash function for Object.
     */
    size_t toHash() @trusted nothrow
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        size_t addr = cast(size_t) cast(void*) this;
        // The bottom log2((void*).alignof) bits of the address will always
        // be 0. Moreover it is likely that each Object is allocated with a
        // separate call to malloc. The alignment of malloc differs from
        // platform to platform, but rather than having special cases for
        // each platform it is safe to use a shift of 4. To minimize
        // collisions in the low bits it is more important for the shift to
        // not be too small than for the shift to not be too big.
        return addr ^ (addr >>> 4);
    }

    /**
     * Compare with another Object obj.
     * Returns:
     *  $(TABLE
     *  $(TR $(TD this &lt; obj) $(TD &lt; 0))
     *  $(TR $(TD this == obj) $(TD 0))
     *  $(TR $(TD this &gt; obj) $(TD &gt; 0))
     *  )
     */
    int opCmp(Object o)
    {
        // BUG: this prevents a compacting GC from working, needs to be fixed
        //return cast(int)cast(void*)this - cast(int)cast(void*)o;

        throw new Exception("need opCmp for class " ~ typeid(this).name);
        //return this !is o;
    }

    /**
     * Test whether $(D this) is equal to $(D o).
     * The default implementation only compares by identity (using the $(D is) operator).
     * Generally, overrides and overloads for $(D opEquals) should attempt to compare objects by their contents.
     * A class will most likely want to add an overload that takes your specific type as the argument
     * and does the content comparison. Then you can override this and forward it to your specific
     * typed overload with a cast. Remember to check for `null` on the typed overload.
     *
     * Examples:
     * ---
     * class Child {
     *    int contents;
     *    // the typed overload first. It can use all the attribute you want
     *    bool opEquals(const Child c) const @safe pure nothrow @nogc
     *    {
     *        if (c is null)
     *            return false;
     *        return this.contents == c.contents;
     *    }
     *
     *    // and now the generic override forwards with a cast
     *    override bool opEquals(Object o)
     *    {
     *        return this.opEquals(cast(Child) o);
     *    }
     * }
     * ---
     */
    bool opEquals(Object o)
    {
        return this is o;
    }

    interface Monitor
    {
        void lock();
        void unlock();
    }
}

/**
 * Information about an interface.
 * When an object is accessed via an interface, an Interface* appears as the
 * first entry in its vtbl.
 */
struct Interface
{
    /// Class info returned by `typeid` for this interface (not for containing class)
    TypeInfo_Class   classinfo;
    void*[]     vtbl;
    size_t      offset;     /// offset to Interface 'this' from Object 'this'
}

/**
 * Array of pairs giving the offset and type information for each
 * member in an aggregate.
 */
struct OffsetTypeInfo
{
    size_t   offset;    /// Offset of member from start of object
    TypeInfo ti;        /// TypeInfo for this member
}

/**
 * Runtime type information about a type.
 * Can be retrieved for any type using a
 * $(GLINK2 expression,TypeidExpression, TypeidExpression).
 */
class TypeInfo
{
    override string toString() const @safe nothrow
    {
        return typeid(this).name;
    }

    override size_t toHash() @trusted const nothrow
    {
        return hashOf(this.toString());
    }

    override int opCmp(Object rhs)
    {
        if (this is rhs)
            return 0;
        auto ti = cast(TypeInfo) rhs;
        if (ti is null)
            return 1;
        return __cmp(this.toString(), ti.toString());
    }

    override bool opEquals(Object o)
    {
        return opEquals(cast(TypeInfo) o);
    }

    bool opEquals(const TypeInfo ti) @safe nothrow const
    {
        /* TypeInfo instances are singletons, but duplicates can exist
         * across DLL's. Therefore, comparing for a name match is
         * sufficient.
         */
        if (this is ti)
            return true;
        return ti && this.toString() == ti.toString();
    }

    /**
     * Computes a hash of the instance of a type.
     * Params:
     *    p = pointer to start of instance of the type
     * Returns:
     *    the hash
     * Bugs:
     *    fix https://issues.dlang.org/show_bug.cgi?id=12516 e.g. by changing this to a truly safe interface.
     */
    size_t getHash(scope const void* p) @trusted nothrow const
    {
        return hashOf(p);
    }

    /// Compares two instances for equality.
    bool equals(in void* p1, in void* p2) const { return p1 == p2; }

    /// Compares two instances for &lt;, ==, or &gt;.
    int compare(in void* p1, in void* p2) const { return _xopCmp(p1, p2); }

    /// Returns size of the type.
    @property size_t tsize() nothrow pure const @safe @nogc { return 0; }

    /// Swaps two instances of the type.
    void swap(void* p1, void* p2) const
    {
        size_t remaining = tsize;
        // If the type might contain pointers perform the swap in pointer-sized
        // chunks in case a garbage collection pass interrupts this function.
        if ((cast(size_t) p1 | cast(size_t) p2) % (void*).alignof == 0)
        {
            while (remaining >= (void*).sizeof)
            {
                void* tmp = *cast(void**) p1;
                *cast(void**) p1 = *cast(void**) p2;
                *cast(void**) p2 = tmp;
                p1 += (void*).sizeof;
                p2 += (void*).sizeof;
                remaining -= (void*).sizeof;
            }
        }
        for (size_t i = 0; i < remaining; i++)
        {
            byte t = (cast(byte *)p1)[i];
            (cast(byte*)p1)[i] = (cast(byte*)p2)[i];
            (cast(byte*)p2)[i] = t;
        }
    }

    /** Get TypeInfo for 'next' type, as defined by what kind of type this is,
    null if none. */
    @property inout(TypeInfo) next() nothrow pure inout @nogc { return null; }

    /**
     * Return default initializer.  If the type should be initialized to all
     * zeros, an array with a null ptr and a length equal to the type size will
     * be returned. For static arrays, this returns the default initializer for
     * a single element of the array, use `tsize` to get the correct size.
     */
version (LDC)
{
    // LDC uses TypeInfo's vtable for the typeof(null) type:
    //   %"typeid(typeof(null))" = type { %object.TypeInfo.__vtbl*, i8* }
    // Therefore this class cannot be abstract, and all methods need implementations.
    // Tested by test14754() in runnable/inline.d, and a unittest below.
    const(void)[] initializer() nothrow pure const @trusted @nogc
    {
        return (cast(const(void)*) null)[0 .. typeof(null).sizeof];
    }
}
else
{
    abstract const(void)[] initializer() nothrow pure const @safe @nogc;
}

    /** Get flags for type: 1 means GC should scan for pointers,
    2 means arg of this type is passed in SIMD register(s) if available */
    @property uint flags() nothrow pure const @safe @nogc { return 0; }

    /// Get type information on the contents of the type; null if not available
    const(OffsetTypeInfo)[] offTi() const { return null; }
    /// Run the destructor on the object and all its sub-objects
    void destroy(void* p) const {}
    /// Run the postblit on the object and all its sub-objects
    void postblit(void* p) const {}


    /// Return alignment of type
    @property size_t talign() nothrow pure const @safe @nogc { return tsize; }

    /** Return internal info on arguments fitting into 8byte.
     * See X86-64 ABI 3.2.3
     */
    version (WithArgTypes) int argTypes(out TypeInfo arg1, out TypeInfo arg2) @safe nothrow
    {
        arg1 = this;
        return 0;
    }
}

class TypeInfo_Enum : TypeInfo
{
    override string toString() const pure { return name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Enum)o;
        return c && this.name == c.name &&
                    this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { return base.getHash(p); }

    override bool equals(in void* p1, in void* p2) const { return base.equals(p1, p2); }

    override int compare(in void* p1, in void* p2) const { return base.compare(p1, p2); }

    override @property size_t tsize() nothrow pure const { return base.tsize; }

    override void swap(void* p1, void* p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }

    override @property uint flags() nothrow pure const { return base.flags; }

    override const(OffsetTypeInfo)[] offTi() const { return base.offTi; }

    override void destroy(void* p) const { return base.destroy(p); }
    override void postblit(void* p) const { return base.postblit(p); }

    override const(void)[] initializer() const
    {
        return m_init.length ? m_init : base.initializer();
    }

    override @property size_t talign() nothrow pure const { return base.talign; }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
    string   name;
    void[]   m_init;
}

// Please make sure to keep this in sync with TypeInfo_P (src/rt/typeinfo/ti_ptr.d)
class TypeInfo_Pointer : TypeInfo
{
    override string toString() const { return m_next.toString() ~ "*"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Pointer)o;
        return c && this.m_next == c.m_next;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        size_t addr = cast(size_t) *cast(const void**)p;
        return addr ^ (addr >> 4);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        return *cast(void**)p1 == *cast(void**)p2;
    }

    override int compare(in void* p1, in void* p2) const
    {
        const v1 = *cast(void**) p1, v2 = *cast(void**) p2;
        return (v1 > v2) - (v1 < v2);
    }

    override @property size_t tsize() nothrow pure const
    {
        return (void*).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (void*).sizeof];
    }

    override void swap(void* p1, void* p2) const
    {
        void* tmp = *cast(void**)p1;
        *cast(void**)p1 = *cast(void**)p2;
        *cast(void**)p2 = tmp;
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return m_next; }
    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    override string toString() const { return value.toString() ~ "[]"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Array)o;
        return c && this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        void[] a = *cast(void[]*)p;
        return getArrayHash(value, a.ptr, a.length);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        if (a1.length != a2.length)
            return false;
        size_t sz = value.tsize;
        for (size_t i = 0; i < a1.length; i++)
        {
            if (!value.equals(a1.ptr + i * sz, a2.ptr + i * sz))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const
    {
        void[] a1 = *cast(void[]*)p1;
        void[] a2 = *cast(void[]*)p2;
        size_t sz = value.tsize;
        size_t len = a1.length;

        if (a2.length < len)
            len = a2.length;
        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(a1.ptr + u * sz, a2.ptr + u * sz);
            if (result)
                return result;
        }
        return (a1.length > a2.length) - (a1.length < a2.length);
    }

    override @property size_t tsize() nothrow pure const
    {
        return (void[]).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (void[]).sizeof];
    }

    override void swap(void* p1, void* p2) const
    {
        void[] tmp = *cast(void[]*)p1;
        *cast(void[]*)p1 = *cast(void[]*)p2;
        *cast(void[]*)p2 = tmp;
    }

    TypeInfo value;

    override @property inout(TypeInfo) next() nothrow pure inout
    {
        return value;
    }

    override @property uint flags() nothrow pure const { return 1; }

    override @property size_t talign() nothrow pure const
    {
        return (void[]).alignof;
    }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(size_t);
        arg2 = typeid(void*);
        return 0;
    }
}

class TypeInfo_StaticArray : TypeInfo
{
    override string toString() const
    {
        import core.internal.string : unsignedToTempString;

        char[20] tmpBuff = void;
        const lenString = unsignedToTempString(len, tmpBuff);

        return (() @trusted => cast(string) (value.toString() ~ "[" ~ lenString ~ "]"))();
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_StaticArray)o;
        return c && this.len == c.len &&
                    this.value == c.value;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        return getArrayHash(value, p, len);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            if (!value.equals(p1 + u * sz, p2 + u * sz))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2) const
    {
        size_t sz = value.tsize;

        for (size_t u = 0; u < len; u++)
        {
            immutable int result = value.compare(p1 + u * sz, p2 + u * sz);
            if (result)
                return result;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return len * value.tsize;
    }

    override void swap(void* p1, void* p2) const
    {
        import core.stdc.string : memcpy;

        size_t remaining = value.tsize * len;
        void[size_t.sizeof * 4] buffer = void;
        while (remaining > buffer.length)
        {
            memcpy(buffer.ptr, p1, buffer.length);
            memcpy(p1, p2, buffer.length);
            memcpy(p2, buffer.ptr, buffer.length);
            p1 += buffer.length;
            p2 += buffer.length;
            remaining -= buffer.length;
        }
        memcpy(buffer.ptr, p1, remaining);
        memcpy(p1, p2, remaining);
        memcpy(p2, buffer.ptr, remaining);
    }

    override const(void)[] initializer() nothrow pure const
    {
        return value.initializer();
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return value; }
    override @property uint flags() nothrow pure const { return value.flags; }

    override void destroy(void* p) const
    {
        immutable sz = value.tsize;
        p += sz * len;
        foreach (i; 0 .. len)
        {
            p -= sz;
            value.destroy(p);
        }
    }

    override void postblit(void* p) const
    {
        immutable sz = value.tsize;
        foreach (i; 0 .. len)
        {
            value.postblit(p);
            p += sz;
        }
    }

    TypeInfo value;
    size_t   len;

    override @property size_t talign() nothrow pure const
    {
        return value.talign;
    }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        return 0;
    }
}

class TypeInfo_AssociativeArray : TypeInfo
{
    override string toString() const
    {
        return value.toString() ~ "[" ~ key.toString() ~ "]";
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_AssociativeArray)o;
        return c && this.key == c.key &&
                    this.value == c.value;
    }

    override bool equals(in void* p1, in void* p2) @trusted const
    {
        //return !!_aaEqual(this, *cast(const AA*) p1, *cast(const AA*) p2);
        return false;
    }

    override hash_t getHash(scope const void* p) nothrow @trusted const
    {
        //return _aaGetHash(cast(AA*)p, this);
        return hash_t.init;
    }

    // BUG: need to add the rest of the functions

    override @property size_t tsize() nothrow pure const
    {
        return (char[int]).sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. (char[int]).sizeof];
    }

    override @property inout(TypeInfo) next() nothrow pure inout { return value; }
    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo value;
    TypeInfo key;

    override @property size_t talign() nothrow pure const
    {
        return (char[int]).alignof;
    }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        arg1 = typeid(void*);
        return 0;
    }
}


class TypeInfo_Vector : TypeInfo
{
    override string toString() const { return "__vector(" ~ base.toString() ~ ")"; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Vector)o;
        return c && this.base == c.base;
    }

    override size_t getHash(scope const void* p) const { return base.getHash(p); }
    override bool equals(in void* p1, in void* p2) const { return base.equals(p1, p2); }
    override int compare(in void* p1, in void* p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void* p1, void* p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return 2; /* passed in SIMD register */ }

    override const(void)[] initializer() nothrow pure const
    {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { return 16; }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
}

class TypeInfo_Function : TypeInfo
{
    override string toString() const pure @trusted
    {
        import core.demangle : demangleType;

        alias SafeDemangleFunctionType = char[] function (const(char)[] buf, char[] dst = null) @safe nothrow pure;
        SafeDemangleFunctionType demangle = cast(SafeDemangleFunctionType) &demangleType;

        return cast(string) demangle(deco);
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Function)o;
        return c && this.deco == c.deco;
    }

    // BUG: need to add the rest of the functions

    override @property size_t tsize() nothrow pure const
    {
        return 0;       // no size for functions
    }

    override const(void)[] initializer() const @safe
    {
        return null;
    }

    TypeInfo next;

    /**
    * Mangled function type string
    */
    string deco;
}

private extern (C) Object _d_newclass(const TypeInfo_Class ci);
private extern (C) int _d_isbaseof(scope TypeInfo_Class child,
    scope const TypeInfo_Class parent) @nogc nothrow pure @safe; // rt.cast_

/**
 * Runtime type information about a class.
 * Can be retrieved from an object instance by using the
 * $(DDSUBLINK spec/expression,typeid_expressions,typeid expression).
 */
class TypeInfo_Class : TypeInfo
{
    override string toString() const pure { return name; }

    override bool opEquals(const TypeInfo o) const
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Class)o;
        return c && this.name == c.name;
    }

    override size_t getHash(scope const void* p) @trusted const
    {
        auto o = *cast(Object*)p;
        return o ? o.toHash() : 0;
    }

    override bool equals(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;

        return (o1 is o2) || (o1 && o1.opEquals(o2));
    }

    override int compare(in void* p1, in void* p2) const
    {
        Object o1 = *cast(Object*)p1;
        Object o2 = *cast(Object*)p2;
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 !is o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const
    {
        return Object.sizeof;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return 1; }

    override @property const(OffsetTypeInfo)[] offTi() nothrow pure const
    {
        return m_offTi;
    }

    final @property auto info() @safe @nogc nothrow pure const return { return this; }
    final @property auto typeinfo() @safe @nogc nothrow pure const return { return this; }

    byte[]      m_init;         /** class static initializer
                                 * (init.length gives size in bytes of class)
                                 */
    string      name;           /// class name
    void*[]     vtbl;           /// virtual function pointer table
    Interface[] interfaces;     /// interfaces this class implements
    TypeInfo_Class   base;           /// base class
    void*       destructor;
    void function(Object) classInvariant;
    enum ClassFlags : uint
    {
        isCOMclass = 0x1,
        noPointers = 0x2,
        hasOffTi = 0x4,
        hasCtor = 0x8,
        hasGetMembers = 0x10,
        hasTypeInfo = 0x20,
        isAbstract = 0x40,
        isCPPclass = 0x80,
        hasDtor = 0x100,
    }
    ClassFlags m_flags;
    void*       deallocator;
    OffsetTypeInfo[] m_offTi;
    void function(Object) defaultConstructor;   // default Constructor

    immutable(void)* m_RTInfo;        // data for precise GC

    /**
     * Create instance of Object represented by 'this'.
     */
    Object create() const
    {
        if (m_flags & 8 && !defaultConstructor)
            return null;
        if (m_flags & 64) // abstract
            return null;
        Object o = _d_newclass(this);
        if (m_flags & 8 && defaultConstructor)
        {
            defaultConstructor(o);
        }
        return o;
    }

   /**
    * Returns true if the class described by `child` derives from or is
    * the class described by this `TypeInfo_Class`. Always returns false
    * if the argument is null.
    *
    * Params:
    *  child = TypeInfo for some class
    * Returns:
    *  true if the class described by `child` derives from or is the
    *  class described by this `TypeInfo_Class`.
    */
    final bool isBaseOf(scope const TypeInfo_Class child) const @nogc nothrow pure @trusted
    {
        if (m_init.length)
        {
            // If this TypeInfo_Class represents an actual class we only need
            // to check the child and its direct ancestors.
            for (auto ti = cast() child; ti !is null; ti = ti.base)
                if (ti is this)
                    return true;
            return false;
        }
        else
        {
            // If this TypeInfo_Class is the .info field of a TypeInfo_Interface
            // we also need to recursively check the child's interfaces.
            return child !is null && _d_isbaseof(cast() child, this);
        }
    }
}

alias ClassInfo = TypeInfo_Class;

class TypeInfo_Interface : TypeInfo
{
    override string toString() const pure { return info.name; }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto c = cast(const TypeInfo_Interface)o;
        return c && this.info.name == typeid(c).name;
    }

    override bool equals(in void* p1, in void* p2) const
    {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);

        return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }

    override int compare(in void* p1, in void* p2) const
    {
        Interface* pi = **cast(Interface ***)*cast(void**)p1;
        Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
        pi = **cast(Interface ***)*cast(void**)p2;
        Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);
        int c = 0;

        // Regard null references as always being "less than"
        if (o1 != o2)
        {
            if (o1)
            {
                if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }

    override @property size_t tsize() nothrow pure const
    {
        return Object.sizeof;
    }

    override const(void)[] initializer() const @trusted
    {
        return (cast(void *)null)[0 .. Object.sizeof];
    }

    override @property uint flags() nothrow pure const { return 1; }

    TypeInfo_Class info;

   /**
    * Returns true if the class described by `child` derives from the
    * interface described by this `TypeInfo_Interface`. Always returns
    * false if the argument is null.
    *
    * Params:
    *  child = TypeInfo for some class
    * Returns:
    *  true if the class described by `child` derives from the
    *  interface described by this `TypeInfo_Interface`.
    */
    final bool isBaseOf(scope const TypeInfo_Class child) const @nogc nothrow pure @trusted
    {
        return child !is null && _d_isbaseof(cast() child, this.info);
    }

   /**
    * Returns true if the interface described by `child` derives from
    * or is the interface described by this `TypeInfo_Interface`.
    * Always returns false if the argument is null.
    *
    * Params:
    *  child = TypeInfo for some interface
    * Returns:
    *  true if the interface described by `child` derives from or is
    *  the interface described by this `TypeInfo_Interface`.
    */
    final bool isBaseOf(scope const TypeInfo_Interface child) const @nogc nothrow pure @trusted
    {
        return child !is null && _d_isbaseof(cast() child.info, this.info);
    }
}


class TypeInfo_Struct : TypeInfo
{
    override size_t toHash() const
    {
        return hashOf(this.mangledName);
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;
        auto s = cast(const TypeInfo_Struct)o;
        return s && this.mangledName == s.mangledName;
    }

    override size_t getHash(scope const void* p) @trusted pure nothrow const
    {
        assert(p);
        if (xtoHash)
        {
            return (*xtoHash)(p);
        }
        else
        {
            return hashOf(p[0 .. initializer().length]);
        }
    }

    override bool equals(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        if (!p1 || !p2)
            return false;
        else if (xopEquals)
        {
            const dg = _memberFunc(p1, xopEquals);
            return dg.xopEquals(p2);
        }
        else if (p1 == p2)
            return true;
        else
            // BUG: relies on the GC not moving objects
            return memcmp(p1, p2, initializer().length) == 0;
    }

    override int compare(in void* p1, in void* p2) @trusted pure nothrow const
    {
        import core.stdc.string : memcmp;

        // Regard null references as always being "less than"
        if (p1 != p2)
        {
            if (p1)
            {
                if (!p2)
                    return true;
                else if (xopCmp)
                {
                    const dg = _memberFunc(p1, xopCmp);
                    return dg.xopCmp(p2);
                }
                else
                    // BUG: relies on the GC not moving objects
                    return memcmp(p1, p2, initializer().length);
            }
            else
                return -1;
        }
        return 0;
    }

    override @property size_t tsize() nothrow pure const
    {
        return initializer().length;
    }

    override const(void)[] initializer() nothrow pure const @safe
    {
        return m_init;
    }

    override @property uint flags() nothrow pure const { return m_flags; }

    override @property size_t talign() nothrow pure const { return m_align; }

    final override void destroy(void* p) const
    {
        if (xdtor)
        {
            if (m_flags & StructFlags.isDynamicType)
                (*xdtorti)(p, this);
            else
                (*xdtor)(p);
        }
    }

    override void postblit(void* p) const
    {
        if (xpostblit)
            (*xpostblit)(p);
    }

    string mangledName;

    void[] m_init;      // initializer; m_init.ptr == null if 0 initialize

    @safe pure nothrow
    {
        size_t   function(in void*)           xtoHash;
        bool     function(in void*, in void*) xopEquals;
        int      function(in void*, in void*) xopCmp;
        string   function(in void*)           xtoString;

        enum StructFlags : uint
        {
            hasPointers = 0x1,
            isDynamicType = 0x2, // built at runtime, needs type info in xdtor
        }
        StructFlags m_flags;
    }
    union
    {
        void function(void*)                xdtor;
        void function(void*, const TypeInfo_Struct ti) xdtorti;
    }
    void function(void*)                    xpostblit;

    uint m_align;

    version (WithArgTypes)
    {
        override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
        {
            arg1 = m_arg1;
            arg2 = m_arg2;
            return 0;
        }
        TypeInfo m_arg1;
        TypeInfo m_arg2;
    }
    immutable(void)* m_RTInfo;                // data for precise GC

    // The xopEquals and xopCmp members are function pointers to member
    // functions, which is not guaranteed to share the same ABI, as it is not
    // known whether the `this` parameter is the first or second argument.
    // This wrapper is to convert it to a delegate which will always pass the
    // `this` parameter in the correct way.
    private struct _memberFunc
    {
        union
        {
            struct // delegate
            {
                const void* ptr;
                const void* funcptr;
            }
            @safe pure nothrow
            {
                bool delegate(in void*) xopEquals;
                int delegate(in void*) xopCmp;
            }
        }
    }
}

class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[] elements;

    override string toString() const
    {
        string s = "(";
        foreach (i, element; elements)
        {
            if (i)
                s ~= ',';
            s ~= element.toString();
        }
        s ~= ")";
        return s;
    }

    override bool opEquals(Object o)
    {
        if (this is o)
            return true;

        auto t = cast(const TypeInfo_Tuple)o;
        if (t && elements.length == t.elements.length)
        {
            for (size_t i = 0; i < elements.length; i++)
            {
                if (elements[i] != t.elements[i])
                    return false;
            }
            return true;
        }
        return false;
    }

    override size_t getHash(scope const void* p) const
    {
        assert(0);
    }

    override bool equals(in void* p1, in void* p2) const
    {
        assert(0);
    }

    override int compare(in void* p1, in void* p2) const
    {
        assert(0);
    }

    override @property size_t tsize() nothrow pure const
    {
        assert(0);
    }

    override const(void)[] initializer() const @trusted
    {
        assert(0);
    }

    override void swap(void* p1, void* p2) const
    {
        assert(0);
    }

    override void destroy(void* p) const
    {
        assert(0);
    }

    override void postblit(void* p) const
    {
        assert(0);
    }

    override @property size_t talign() nothrow pure const
    {
        assert(0);
    }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        assert(0);
    }
}

class TypeInfo_Const : TypeInfo
{
    override string toString() const
    {
        return cast(string) ("const(" ~ base.toString() ~ ")");
    }

    //override bool opEquals(Object o) { return base.opEquals(o); }
    override bool opEquals(Object o)
    {
        if (this is o)
            return true;

        if (typeid(this) != typeid(o))
            return false;

        auto t = cast(TypeInfo_Const)o;
        return base.opEquals(t.base);
    }

    override size_t getHash(scope const void *p) const { return base.getHash(p); }
    override bool equals(in void *p1, in void *p2) const { return base.equals(p1, p2); }
    override int compare(in void *p1, in void *p2) const { return base.compare(p1, p2); }
    override @property size_t tsize() nothrow pure const { return base.tsize; }
    override void swap(void *p1, void *p2) const { return base.swap(p1, p2); }

    override @property inout(TypeInfo) next() nothrow pure inout { return base.next; }
    override @property uint flags() nothrow pure const { return base.flags; }

    override const(void)[] initializer() nothrow pure const
    {
        return base.initializer();
    }

    override @property size_t talign() nothrow pure const { return base.talign; }

    version (WithArgTypes) override int argTypes(out TypeInfo arg1, out TypeInfo arg2)
    {
        return base.argTypes(arg1, arg2);
    }

    TypeInfo base;
}

class TypeInfo_Invariant : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("immutable(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Shared : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("shared(" ~ base.toString() ~ ")");
    }
}

class TypeInfo_Inout : TypeInfo_Const
{
    override string toString() const
    {
        return cast(string) ("inout(" ~ base.toString() ~ ")");
    }
}

///////////////////////////////////////////////////////////////////////////////
// Throwable
///////////////////////////////////////////////////////////////////////////////


/**
 * The base class of all thrown objects.
 *
 * All thrown objects must inherit from Throwable. Class $(D Exception), which
 * derives from this class, represents the category of thrown objects that are
 * safe to catch and handle. In principle, one should not catch Throwable
 * objects that are not derived from $(D Exception), as they represent
 * unrecoverable runtime errors. Certain runtime guarantees may fail to hold
 * when these errors are thrown, making it unsafe to continue execution after
 * catching them.
 */
class Throwable : Object
{
    interface TraceInfo
    {
        int opApply(scope int delegate(ref const(char[]))) const;
        int opApply(scope int delegate(ref size_t, ref const(char[]))) const;
        string toString() const;
    }

    alias TraceDeallocator = void function(TraceInfo) nothrow;

    string      msg;    /// A message describing the error.

    /**
     * The _file name of the D source code corresponding with
     * where the error was thrown from.
     */
    string      file;
    /**
     * The _line number of the D source code corresponding with
     * where the error was thrown from.
     */
    size_t      line;

    /**
     * The stack trace of where the error happened. This is an opaque object
     * that can either be converted to $(D string), or iterated over with $(D
     * foreach) to extract the items in the stack trace (as strings).
     */
    TraceInfo   info;

    /**
     * If set, this is used to deallocate the TraceInfo on destruction.
     */
    TraceDeallocator infoDeallocator;


    /**
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    private Throwable   nextInChain;

    private uint _refcount;     // 0 : allocated by GC
                                // 1 : allocated by _d_newThrowable()
                                // 2.. : reference count + 1

    /**
     * Returns:
     * A reference to the _next error in the list. This is used when a new
     * $(D Throwable) is thrown from inside a $(D catch) block. The originally
     * caught $(D Exception) will be chained to the new $(D Throwable) via this
     * field.
     */
    @property inout(Throwable) next() @safe inout return scope pure nothrow @nogc { return nextInChain; }

    /**
     * Replace next in chain with `tail`.
     * Use `chainTogether` instead if at all possible.
     */
    @property void next(Throwable tail) @safe scope pure nothrow @nogc
    {
        if (tail && tail._refcount)
            ++tail._refcount;           // increment the replacement *first*

        auto n = nextInChain;
        nextInChain = null;             // sever the tail before deleting it

        //if (n && n._refcount)
        //    _d_delThrowable(n);         // now delete the old tail

        nextInChain = tail;             // and set the new tail
    }

    /**
     * Returns:
     *  mutable reference to the reference count, which is
     *  0 - allocated by the GC, 1 - allocated by _d_newThrowable(),
     *  and >=2 which is the reference count + 1
     * Note:
     *  Marked as `@system` to discourage casual use of it.
     */
    @system @nogc final pure nothrow ref uint refcount() return { return _refcount; }

    /**
     * Loop over the chain of Throwables.
     */
    int opApply(scope int delegate(Throwable) dg)
    {
        int result = 0;
        for (Throwable t = this; t; t = t.nextInChain)
        {
            result = dg(t);
            if (result)
                break;
        }
        return result;
    }

    /**
     * Append `e2` to chain of exceptions that starts with `e1`.
     * Params:
     *  e1 = start of chain (can be null)
     *  e2 = second part of chain (can be null)
     * Returns:
     *  Throwable that is at the start of the chain; null if both `e1` and `e2` are null
     */
    static @__future @system @nogc pure nothrow Throwable chainTogether(return scope Throwable e1, return scope Throwable e2)
    {
        if (!e1)
            return e2;
        if (!e2)
            return e1;
        if (e2.refcount())
            ++e2.refcount();

        for (auto e = e1; 1; e = e.nextInChain)
        {
            if (!e.nextInChain)
            {
                e.nextInChain = e2;
                break;
            }
        }
        return e1;
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain = null)
    {
        this.msg = msg;
        this.nextInChain = nextInChain;
        if (nextInChain && nextInChain._refcount)
            ++nextInChain._refcount;
        //this.info = _d_traceContext();
    }

    @nogc @safe pure nothrow this(string msg, string file, size_t line, Throwable nextInChain = null)
    {
        this(msg, nextInChain);
        this.file = file;
        this.line = line;
        //this.info = _d_traceContext();
    }

    @trusted nothrow ~this()
    {
        //if (nextInChain && nextInChain._refcount)
        //    _d_delThrowable(nextInChain);
        // handle owned traceinfo
        if (infoDeallocator !is null)
        {
            infoDeallocator(info);
            info = null; // avoid any kind of dangling pointers if we can help
                         // it.
        }
    }

    /**
     * Overrides $(D Object.toString) and returns the error message.
     * Internally this forwards to the $(D toString) overload that
     * takes a $(D_PARAM sink) delegate.
     */
    override string toString()
    {
        string s;
        toString((in buf) { s ~= buf; });
        return s;
    }

    /**
     * The Throwable hierarchy uses a toString overload that takes a
     * $(D_PARAM _sink) delegate to avoid GC allocations, which cannot be
     * performed in certain error situations.  Override this $(D
     * toString) method to customize the error message.
     */
    void toString(scope void delegate(in char[]) sink) const
    {
        import core.internal.string : unsignedToTempString;

        char[20] tmpBuff = void;

        sink(typeid(this).name);
        sink("@"); sink(file);
        sink("("); sink(unsignedToTempString(line, tmpBuff)); sink(")");

        if (msg.length)
        {
            sink(": "); sink(msg);
        }
        if (info)
        {
            try
            {
                sink("\n----------------");
                foreach (t; info)
                {
                    sink("\n"); sink(t);
                }
            }
            catch (Throwable)
            {
                // ignore more errors
            }
        }
    }

    /**
     * Get the message describing the error.
     *
     * This getter is an alternative way to access the Exception's message,
     * with the added advantage of being override-able in subclasses.
     * Subclasses are hence free to do their own memory managements without
     * being tied to the requirement of providing a `string` in a field.
     *
     * The default behavior is to return the `Throwable.msg` field.
     *
     * Returns:
     *  A message representing the cause of the `Throwable`
     */
    @__future const(char)[] message() const @safe nothrow
    {
        return this.msg;
    }
}


/**
 * The base class of all errors that are safe to catch and handle.
 *
 * In principle, only thrown objects derived from this class are safe to catch
 * inside a $(D catch) block. Thrown objects not derived from Exception
 * represent runtime errors that should not be caught, as certain runtime
 * guarantees may not hold, making it unsafe to continue program execution.
 */
class Exception : Throwable
{

    /**
     * Creates a new instance of Exception. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Exception; the $(D throw) expression should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
    }

    @nogc @safe pure nothrow this(string msg, Throwable nextInChain, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line, nextInChain);
    }
}

/**
 * The base class of all unrecoverable runtime errors.
 *
 * This represents the category of $(D Throwable) objects that are $(B not)
 * safe to catch and handle. In principle, one should not catch Error
 * objects, as they represent unrecoverable runtime errors.
 * Certain runtime guarantees may fail to hold when these errors are
 * thrown, making it unsafe to continue execution after catching them.
 */
class Error : Throwable
{
    /**
     * Creates a new instance of Error. The nextInChain parameter is used
     * internally and should always be $(D null) when passed by user code.
     * This constructor does not automatically throw the newly-created
     * Error; the $(D throw) statement should be used for that purpose.
     */
    @nogc @safe pure nothrow this(string msg, Throwable nextInChain = null)
    {
        super(msg, nextInChain);
        bypassedException = null;
    }

    @nogc @safe pure nothrow this(string msg, string file, size_t line, Throwable nextInChain = null)
    {
        super(msg, file, line, nextInChain);
        bypassedException = null;
    }

    /** The first $(D Exception) which was bypassed when this Error was thrown,
    or $(D null) if no $(D Exception)s were pending. */
    Throwable   bypassedException;
}

public import core.internal.array.appending : _d_arrayappendcTXImpl;
public import core.internal.array.appending : _d_arrayappendT;
public import core.internal.array.comparison : __cmp;
public import core.internal.array.equality : __equals;

//public import core.internal.array.casting: __ArrayCast;
//public import core.internal.array.concatenation : _d_arraycatnTXImpl;
//public import core.internal.array.construction : _d_arrayctor;
//public import core.internal.array.construction : _d_arraysetctor;
//public import core.internal.array.arrayassign : _d_arrayassign_l;
//public import core.internal.array.arrayassign : _d_arrayassign_r;
//public import core.internal.array.arrayassign : _d_arraysetassign;
//public import core.internal.array.capacity: _d_arraysetlengthTImpl;
//
//public import core.internal.dassert: _d_assert_fail;
//
//public import core.internal.destruction: __ArrayDtor;
//
//public import core.internal.moving: __move_post_blt;
//
//public import core.internal.postblit: __ArrayPostblit;
//
//public import core.internal.switch_: __switch;
//public import core.internal.switch_: __switch_error;
//
//public import core.lifetime : _d_delstructImpl;
//public import core.lifetime : _d_newThrowable;

/++
    Implementation for class opEquals override. Calls the class-defined methods after a null check.
    Please note this is not nogc right now, even if your implementation is, because of
    the typeinfo name string compare. This is because of dmd's dll implementation. However,
    it can infer to @safe if your class' opEquals is.
+/
bool opEquals(LHS, RHS)(LHS lhs, RHS rhs)
if ((is(LHS : const Object) || is(LHS : const shared Object)) &&
    (is(RHS : const Object) || is(RHS : const shared Object)))
{
    static if (__traits(compiles, lhs.opEquals(rhs)) && __traits(compiles, rhs.opEquals(lhs)))
    {
        // If aliased to the same object or both null => equal
        if (lhs is rhs) return true;

        // If either is null => non-equal
        if (lhs is null || rhs is null) return false;

        if (!lhs.opEquals(rhs)) return false;

        // If same exact type => one call to method opEquals
        if (typeid(lhs) is typeid(rhs) ||
            !__ctfe && typeid(lhs).opEquals(typeid(rhs)))
                /* CTFE doesn't like typeid much. 'is' works, but opEquals doesn't
                (issue 7147). But CTFE also guarantees that equal TypeInfos are
                always identical. So, no opEquals needed during CTFE. */
        {
            return true;
        }

        // General case => symmetric calls to method opEquals
        return rhs.opEquals(lhs);
    }
    else
    {
        // this is a compatibility hack for the old const cast behavior
        // if none of the new overloads compile, we'll go back plain Object,
        // including casting away const. It does this through the pointer
        // to bypass any opCast that may be present on the original class.
        return .opEquals!(Object, Object)(*cast(Object*) &lhs, *cast(Object*) &rhs);

    }
}

private inout(TypeInfo) getElement(return scope inout TypeInfo value) @trusted pure nothrow
{
    TypeInfo element = cast() value;
    for (;;)
    {
        if (auto qualified = cast(TypeInfo_Const) element)
            element = qualified.base;
        else if (auto redefined = cast(TypeInfo_Enum) element)
            element = redefined.base;
        else if (auto staticArray = cast(TypeInfo_StaticArray) element)
            element = staticArray.value;
        else if (auto vector = cast(TypeInfo_Vector) element)
            element = vector.base;
        else
            break;
    }
    return cast(inout) element;
}

private size_t getArrayHash(const scope TypeInfo element, const scope void* ptr, const size_t count) @trusted nothrow
{
    if (!count)
        return 0;

    const size_t elementSize = element.tsize;
    if (!elementSize)
        return 0;

    static bool hasCustomToHash(const scope TypeInfo value) @trusted pure nothrow
    {
        const element = getElement(value);

        if (const struct_ = cast(const TypeInfo_Struct) element)
            return !!struct_.xtoHash;

        return cast(const TypeInfo_Array) element
            || cast(const ClassInfo) element
            || cast(const TypeInfo_Interface) element;
    }

    if (!hasCustomToHash(element))
        return hashOf(ptr[0 .. elementSize * count]);

    size_t hash = 0;
    foreach (size_t i; 0 .. count)
        hash = hashOf(element.getHash(ptr + i * elementSize), hash);
    return hash;
}

