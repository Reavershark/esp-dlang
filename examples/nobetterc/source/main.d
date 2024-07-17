module main;

import ministd.conv : to;
import ministd.stdio : writeln, writefln;
import ministd.typecons : Appender, DynArray, UniqueHeapArray;

@safe:

abstract class IntGenerator
{
    bool empty() const => false;
    abstract int front() const;
    abstract void popFront();
}

class FibonacciGenerator : IntGenerator
{
    int a = 1, b = 1;

    override
    int front() const => a;

    override
    void popFront()
    {
        const int next = a + b;
        a = b;
        b = next;
    }
}

extern(C)
void app_main()
{
    writeln("Look, no betterC!");

    writeln("Creating a FibonacciGenerator on the heap");
    // Manual memory management example, see UniqueHeap!T and SharedHeap!T for auto
    IntGenerator gen = dalloc!FibonacciGenerator;
    scope(exit) dfree(gen);

    writeln("Constructing a string of fibonacci numbers");
    Appender!char appender;
    foreach (i; 0 .. 20)
    {
        UniqueHeapArray!char numberStr = gen.front.to!(char[]);
        gen.popFront;
        if (i > 0)
            appender.put(" ");
        appender.put(numberStr);
    }
    DynArray!char numbersString = appender.moveArray;

    writefln!"Some fibonacci numbers: %s"(numbersString.get);
}
