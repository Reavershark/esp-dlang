#!/usr/bin/env rdmd

import std.file;
import std.range;

void main()
{
  auto d_files = dirEntries("include", "*_dpp.d", SpanMode.depth);
  foreach (DirEntry entry; d_files)
    entry.remove;
}
