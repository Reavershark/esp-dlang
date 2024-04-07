#!/usr/bin/env python3
from pathlib import Path
from typing import List
import json
import sys

def get_default_esp_idf_flags(target: str):
    return " ".join(list_default_esp_idf_flags(target))

def list_default_esp_idf_flags(target: str):
    dflags = []
    if target == "esp32":
        dflags += ["--betterC", "--mcpu=esp32", "--mtriple=xtensa-esp32-elf"]
        dflags += ["-P-w"] # Supress C preprocessor warnings
        dflags += [f"-P-D{s}" for s in list_importc_defines()]
        dflags += [f"-P-D{s}" for s in list_esp_idf_importc_defines()]
        dflags += [f"-P-I{s}" for s in list_esp_idf_importc_include_paths()]
    else:
        raise Exception(f"Unsupported target {target}")
    return dflags

def list_importc_defines():
    return [
        "__IMPORTC__"
    ]

def list_esp_idf_importc_defines():
    return [
        "__XTENSA__",
        "__GLIBC_USE(arg)=0"
    ]

def list_esp_idf_importc_include_paths():
    project_description_path = Path("build", "project_description.json")
    if not project_description_path.exists():
        raise Exception(f"File {project_description_path} does not exist. Configure project first?")

    res: List[Path] = []

    res.append(Path("build", "config").resolve())

    json_root = json.load(open(project_description_path, "r"))

    for component_name, json_component in json_root["build_component_info"].items():
        component_dir = Path(json_component["dir"])
        res.append(Path(component_dir, "include"))
        for extra_include_path_str in json_component["include_dirs"]:
            extra_include_path = Path(extra_include_path_str)
            if extra_include_path.is_absolute():
                res.append(extra_include_path)
            else:
                res.append(Path(component_dir, extra_include_path))

    res.append(Path(json_root["idf_path"], "components", "soc", json_root["target"], "include"))

    toolchain_path = Path(json_root["c_compiler"]).parents[1]
    toolchain_include_path = Path(toolchain_path, toolchain_path.name, "include")
    res.append(toolchain_include_path)

    return res

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: dflags.py [target]")
        sys.exit(1)
    print(get_default_esp_idf_flags(sys.argv[1]))
