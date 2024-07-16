module main;

@safe nothrow @nogc:

pragma(printf) extern (C) @trusted
int printf(scope const char* fmt, scope const...);

extern(C)
void app_main()
{
    printf("Hello from D!\n");
}
