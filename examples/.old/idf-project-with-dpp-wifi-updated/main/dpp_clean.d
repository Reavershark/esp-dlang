#!/usr/bin/env rdmd

import std.file : dirEntries, DirEntry, remove, SpanMode;
import std.stdio : writeln;

void main()
{
  pragma(msg, "Compiling dpp_clean.d");
  writeln("Running dpp_clean.d");

  auto d_files = dirEntries(".", "*_dpp.d", SpanMode.depth);
  foreach (DirEntry entry; d_files)
    entry.remove;
}
