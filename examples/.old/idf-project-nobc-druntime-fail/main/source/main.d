module main;

@safe:

pragma(printf)
extern(C) int printf(scope const char* fmt, scope const ...) nothrow @nogc;

extern(C) void app_main() @trusted
{
    //int a = 9;
    int* a = new int();
    *a = 10;
    printf("a = %d", *a);

    //new ubyte;
    //new ushort;
    //new uint;
    //new ulong;

    //destroy(a);
}
