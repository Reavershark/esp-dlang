#!/usr/bin/env rdmd

import std.file;
import std.range;
import std.stdio;

void main()
{
  pragma(msg, "Compiling dpp_clean.d");
  writeln("Running dpp_clean.d");

  auto d_files = dirEntries("source", "*_dpp.d", SpanMode.depth);
  foreach (DirEntry entry; d_files)
    entry.remove;
}
