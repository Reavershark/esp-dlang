module dcode;

extern(C) int printf (scope const char * fmt, scope const ...);

extern (C) void dlang_main()
{
    int i = 0;
    printf("Hello, dlang says : i = %d\r\n", i);
}
