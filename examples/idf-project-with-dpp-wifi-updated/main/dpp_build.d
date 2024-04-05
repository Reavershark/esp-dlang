#!/usr/bin/env rdmd

import std.algorithm : map, startsWith;
import std.array : array, join, split;
import std.exception : enforce;
import std.file : dirEntries, DirEntry, exists, readText, SpanMode;
import std.format : f = format;
import std.json : JSONValue, parseJSON;
import std.parallelism : parallel;
import std.process : env = environment, execute;
import std.range : empty;
import std.stdio;

void main()
{
    pragma(msg, "Compiling dpp_build.d");
    writeln("Running dpp_build.d");

    string[] commandWithoutFiles;
    commandWithoutFiles ~= ["dub", "run", "--yes", "--build=release", "--compiler=dmd", "dpp@0.5.2", "--"];
    commandWithoutFiles ~= ["-n", "--preprocess-only"];
    commandWithoutFiles ~= ["__XTENSA__", "SSIZE_MAX"].defineArgs;
    commandWithoutFiles ~= ["__assert"].ignoreSymbolArgs;
    commandWithoutFiles ~= includeArgs;

    string[] fileList = buildFileList;
    if (fileList.empty)
        writeln("All *_dpp.d files are up to date.");

    foreach (file; (fileList))
    {
        writefln!"Processing file \"%s\""(file);
        auto result = execute(commandWithoutFiles ~ file);
        if (result.status != 0)
            throw new Exception(f!"Error executing command: %s"(result.output));
        writefln!"Finished processing file \"%s\""(file);
    }
}

string[] buildFileList()
{
    string[] res;
    foreach (DirEntry dpp_dpp_entry; dirEntries(".", "*_dpp.dpp", SpanMode.depth))
    {
        string dpp_d_name = dpp_dpp_entry.name[0 .. $ - 4] ~ ".d";
        if (exists(dpp_d_name))
        {
            DirEntry dpp_d_entry = DirEntry(dpp_d_name);
            // if newer than source, skip
            if (dpp_d_entry.timeLastModified > dpp_dpp_entry.timeLastModified)
                continue;
        }
        res ~= dpp_dpp_entry.name;
    }
    return res;
}

string[] defineArgs(string[] defines)
{
    return defines
        .map!((string define) => "--define=" ~ define)
        .array;
}

string[] ignoreSymbolArgs(string[] symbols)
{
    return symbols
        .map!((string symbol) => "--ignore-cursor=" ~ symbol)
        .array;
}

string[] includeArgs()
{
    string[] res;
    res ~= "../build/config";

    enum projectDescPath = "../build/project_description.json";
    if (!projectDescPath.exists)
        throw new Exception(f!"Project description file %s does not exists."(projectDescPath));

    immutable JSONValue jsonRoot = projectDescPath.readText.parseJSON;

    foreach (string componentName, JSONValue jsonComponent; jsonRoot["build_component_info"].object)
    {
        immutable string componentDir = jsonComponent["dir"].str;

        // Always the case, even if not explicitly defined in include_dirs
        res ~= componentDir ~ "/include";

        // Add paths in include_dirs
        foreach (immutable string includePath; jsonComponent["include_dirs"].array.map!"a.str")
        {
            enforce(includePath.length, f!"Component %s has an empty include path"(componentName));
            if (includePath.startsWith("/"))
                res ~= includePath;
            else
                res ~= componentDir ~ "/" ~ includePath;
        }
    }

    // Target-specific includes
    res ~= f!"%s/components/soc/%s/include"(jsonRoot["idf_path"].str, jsonRoot["target"].str);

    string[] toolChainIncludePath = jsonRoot["c_compiler"].str.split("/")[0 .. $ - 2];
    toolChainIncludePath ~= toolChainIncludePath[$ - 1];
    toolChainIncludePath ~= "include";
    res ~= toolChainIncludePath.join("/");

    import std.algorithm : each;
    res.each!writeln;

    return res
        .map!((string path) => "--include-path=" ~ path)
        .array;
}
