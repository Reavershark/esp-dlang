module app;

pragma(printf)
extern(C)
int printf(scope const char* fmt, scope const ...);

extern(C)
void app_main()
{
    printf("Hello from dlang!\n");
}
