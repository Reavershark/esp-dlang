module main;

@safe nothrow @nogc:

pragma(printf) extern (C) @trusted
int printf(scope const char* fmt, scope const...);

extern(C) @trusted
void* malloc(size_t size);

extern(C)
void app_main()
{
    printf("Hello from D!\n");
    
    size_t i;
    while (true)
    {
        void* ret = malloc(1024);
        printf("Malloc: %d %p\n", i, ret);
        if (ret is null)
            break;
        i++;
    }

    printf("Allocated %d blocks of 1024 bytes on the heap\n", i);
}
