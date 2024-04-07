#!/usr/bin/env python3
from pathlib import Path
from typing import Dict, List
import json
import sys

def get_default_esp_idf_flags():
    return " ".join(list_default_esp_idf_flags())

def list_default_esp_idf_flags():
    dflags = []
    dflags += ["--betterC"]
    dflags += get_esp_idf_ldc_target_flags()
    dflags += ["-P-w"] # Supress C preprocessor warnings
    dflags += [f"-P-D{s}" for s in list_importc_defines()]
    dflags += [f"-P-D{s}" for s in list_esp_idf_importc_defines()]
    dflags += [f"-P-I{s}" for s in list_esp_idf_importc_include_paths()]
    return dflags

def list_importc_defines() -> List[str]:
    return [
        "__IMPORTC__"
    ]

def get_esp_idf_project_description() -> Dict:
    project_description_path = Path("build", "project_description.json")
    if not project_description_path.exists():
        raise Exception(f"File {project_description_path} does not exist. Configure project first?")
    return json.load(open(project_description_path, "r"))

def get_esp_idf_target() -> str:
    return get_esp_idf_project_description()["target"]

def get_esp_idf_ldc_target_flags() -> List[str]:
    target = get_esp_idf_target()
    if target in ["esp32", "esp32s2", "esp32s3"]:
        return [f"--mcpu={target}", f"--mtriple=xtensa-{target}-elf"]
    else:
        raise Exception(f"Unsupported target {target}")

def list_esp_idf_importc_defines() -> List[str]:
    return [
        "__XTENSA__",
        "__GLIBC_USE(arg)=0"
    ]

def list_esp_idf_importc_include_paths() -> List[str]:
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
    print(get_default_esp_idf_flags())
