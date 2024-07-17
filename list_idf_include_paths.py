#!/usr/bin/env python3
from pathlib import Path
from typing import List
import json

def list_esp_idf_include_paths() -> List[str]:
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
    for path in list_esp_idf_include_paths():
        print(path)
