#!/usr/bin/env python3
"""فاحص ثابت لمشروع Godot — يعمل بلا محرّك Godot.

يفحص ما تكسر غالبًا عند تحرير المشاهد يدويًا:
  1. سلامة ملفات .tscn: عدد load_steps، ومراجع ExtResource/SubResource، ووجود الملفات على القرص.
  2. مسارات العُقد: كل `$Path` و`get_node(...)` و`get_node_or_null(...)` مقابل شجرة المشهد الحقيقية
     (مع حلّ المشاهد المُستنسخة recursively).
  3. مسارات `res://` داخل preload/load.
  4. نظافة GDScript: خلط المسافات مع الجدولة، والأقواس غير المتوازنة.
  5. المجموعات: كل `get_first_node_in_group("x")` له `add_to_group("x")` في مكان ما.
  6. الإشارات: كل `.emit(` على إشارة معلنة في نفس الملف.

الاستخدام:  python3 ci/static_check.py
"""

from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

errors: list[str] = []
warnings: list[str] = []
checks = 0


def ok(msg: str) -> None:
    global checks
    checks += 1


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def read(path: str) -> str:
    with open(os.path.join(ROOT, path), encoding="utf-8") as handle:
        return handle.read()


def res_to_fs(path: str) -> str:
    return path[len("res://"):] if path.startswith("res://") else path


# ---------------------------------------------------------------- مشاهد .tscn

NODE_RE = re.compile(r'\[node name="([^"]+)"([^\]]*)\]')
EXT_RE = re.compile(r'\[ext_resource ([^\]]*)\]')
SUB_RE = re.compile(r'\[sub_resource ([^\]]*)\]')
PROP_RE = re.compile(r'(\w+)="([^"]*)"')


def parse_scene(rel_path: str) -> dict:
    text = read(rel_path)
    ext: dict[str, dict] = {}
    for body in EXT_RE.findall(text):
        props = dict(PROP_RE.findall(body))
        if "id" in props:
            ext[props["id"]] = props
    subs = [dict(PROP_RE.findall(body)) for body in SUB_RE.findall(text)]
    # نمرّ سطرًا سطرًا حتى ترتبط خواص كل عقدة (script/instance/...) بترويسها.
    nodes: list[dict] = []
    current: dict | None = None
    for line in text.splitlines():
        header = NODE_RE.match(line.strip())
        if header:
            props = dict(PROP_RE.findall(header.group(2)))
            body = header.group(2)
            # instance=ExtResource("id") لا يُلتقط بـ PROP_RE لأن = لا تليها علامة اقتباس مباشرة.
            instance_match = re.search(r'instance=ExtResource\("([^"]+)"\)', body)
            script_match = re.search(r'script=ExtResource\("([^"]+)"\)', body)
            current = {"name": header.group(1), "parent": props.get("parent", "."),
                       "type": props.get("type", ""),
                       "instance": f'ExtResource("{instance_match.group(1)}")' if instance_match else "",
                       "script": f'ExtResource("{script_match.group(1)}")' if script_match else ""}
            nodes.append(current)
            continue
        if line.startswith("[") or current is None:
            continue
        prop = re.match(r'\s*([A-Za-z_][\w/]*)\s*=\s*(.*)', line)
        if not prop:
            continue
        key, value = prop.group(1), prop.group(2).strip()
        if key == "script":
            current["script"] = value
        elif key == "instance":
            current["instance"] = value
    load_steps = 0
    m = re.search(r"load_steps=(\d+)", text)
    if m:
        load_steps = int(m.group(1))
    return {"path": rel_path, "ext": ext, "subs": subs, "nodes": nodes,
            "load_steps": load_steps, "text": text}


SCENE_CACHE: dict[str, dict] = {}


def scene(rel_path: str) -> dict:
    if rel_path not in SCENE_CACHE:
        SCENE_CACHE[rel_path] = parse_scene(rel_path)
    return SCENE_CACHE[rel_path]


def node_paths(sc: dict) -> set[str]:
    """كل مسارات العُقد داخل مشهد، مع دمج الأطفال من المشاهد المُستنسخة."""
    paths: set[str] = set()
    for node in sc["nodes"]:
        if node["parent"] == ".":
            full = node["name"]
        else:
            full = f"{node['parent']}/{node['name']}"
        paths.add(full)
        if node["instance"]:
            ext_id = re.search(r'ExtResource\("([^"]+)"\)', node["instance"])
            if not ext_id:
                continue
            info = sc["ext"].get(ext_id.group(1))
            if not info or not info.get("path", "").endswith(".tscn"):
                continue
            child_rel = res_to_fs(info["path"])
            if not os.path.exists(os.path.join(ROOT, child_rel)):
                continue
            for child in node_paths(scene(child_rel)):
                paths.add(f"{full}/{child}")
    return paths


def script_of_node(sc: dict, node: dict) -> str | None:
    """سكربت العُقدة: من خاصيتها أو من جذر المشهد المُستنسخ."""
    if node["script"]:
        m = re.search(r'ExtResource\("([^"]+)"\)', node["script"])
        if m and m.group(1) in sc["ext"]:
            return res_to_fs(sc["ext"][m.group(1)]["path"])
    if node["instance"]:
        m = re.search(r'ExtResource\("([^"]+)"\)', node["instance"])
        if m and m.group(1) in sc["ext"]:
            info = sc["ext"][m.group(1)]
            if info.get("path", "").endswith(".tscn"):
                child_rel = res_to_fs(info["path"])
                if os.path.exists(os.path.join(ROOT, child_rel)):
                    child = scene(child_rel)
                    for child_node in child["nodes"]:
                        if child_node["parent"] == "." and child_node["script"]:
                            mm = re.search(r'ExtResource\("([^"]+)"\)', child_node["script"])
                            if mm and mm.group(1) in child["ext"]:
                                return res_to_fs(child["ext"][mm.group(1)]["path"])
    return None


def normalize(base: str, rel: str) -> str:
    parts = base.split("/") if base else []
    for segment in rel.split("/"):
        if segment == "..":
            if parts:
                parts.pop()
        elif segment in ("", "."):
            continue
        else:
            parts.append(segment)
    return "/".join(parts)


def check_scenes() -> None:
    scene_files = []
    for dirpath, _dirs, files in os.walk(os.path.join(ROOT, "scenes")):
        for name in files:
            if name.endswith(".tscn"):
                scene_files.append(os.path.relpath(os.path.join(dirpath, name), ROOT))
    for rel in sorted(scene_files):
        sc = scene(rel)
        expected = len(sc["ext"]) + len(sc["subs"]) + 1
        if sc["load_steps"] != expected:
            err(f"{rel}: load_steps={sc['load_steps']} but ext+sub+1={expected}")
        else:
            ok("load_steps")
        declared_ext = set(sc["ext"])
        declared_sub = {s.get("id") for s in sc["subs"]}
        for used in set(re.findall(r'ExtResource\("([^"]+)"\)', sc["text"])):
            if used not in declared_ext:
                err(f"{rel}: ExtResource(\"{used}\") not declared")
            else:
                ok("ext ref")
        for used in set(re.findall(r'SubResource\("([^"]+)"\)', sc["text"])):
            if used not in declared_sub:
                err(f"{rel}: SubResource(\"{used}\") not declared")
            else:
                ok("sub ref")
        for ext_id, info in sc["ext"].items():
            path = info.get("path", "")
            if path.startswith("res://") and not os.path.exists(os.path.join(ROOT, res_to_fs(path))):
                err(f"{rel}: ext_resource {ext_id} -> missing file {path}")
            else:
                ok("ext file")
        check_node_paths(rel, sc)


def check_node_paths(rel: str, sc: dict) -> None:
    paths = node_paths(sc)
    for index, node in enumerate(sc["nodes"]):
        # مسارات العُقد مخزّنة نسبةً إلى جذر المشهد: جذر المشهد نفسه مساره سلسلة فارغة.
        if index == 0 and node["parent"] == ".":
            own = ""
        else:
            own = node["name"] if node["parent"] == "." else f"{node['parent']}/{node['name']}"
        base = own
        script_rel = script_of_node(sc, node)
        if not script_rel or not os.path.exists(os.path.join(ROOT, script_rel)):
            continue
        text = read(script_rel)
        wanted: list[tuple[str, str]] = []
        for m in re.finditer(r'@onready var \w+[^=\n]*= \$(\S+)', text):
            wanted.append((m.group(1).strip('"'), "$"))
        for m in re.finditer(r'get_node(?:_or_null)?\(\s*"([^"]+)"\s*\)', text):
            wanted.append((m.group(1), "get_node"))
        for target, kind in wanted:
            if target.startswith("res://") or ":" in target:
                continue
            if kind == "$" and not target.startswith("."):
                resolved = normalize(base, target)
            elif target.startswith("."):
                resolved = normalize(base, target)
            else:
                continue  # مسار مطلق/ديناميكي — لا يُتحقق منه هنا
            if resolved not in paths:
                err(f"{script_rel} (node \"{node['name']}\" at /{base}): {kind} \"{target}\" -> \"{resolved}\" not in {rel}")
            else:
                ok("node path")
        # أنماط get_parent().get_node_or_null("X")
        for m in re.finditer(r'get_parent\(\)\.get_node_or_null\(\s*"([^"]+)"\s*\)', text):
            if base == "":
                continue  # get_parent() من جذر المشهد يخرج عن المشهد نفسه
            parent_of_base = "" if "/" not in base else base.rsplit("/", 1)[0]
            resolved = normalize(parent_of_base, m.group(1)) if parent_of_base else m.group(1)
            if resolved not in paths:
                err(f"{script_rel} (node {base}): get_parent().get_node_or_null(\"{m.group(1)}\") -> \"{resolved}\" not in {rel}")
            else:
                ok("parent node path")


# ------------------------------------------------------------------- GDScript

def strip_noise(text: str) -> str:
    """يحذف النصوص بين علامات الاقتباس والتعليقات حتى لا تُحسب أقواسها."""
    out = []
    for line in text.splitlines():
        cleaned = []
        index = 0
        quote = ""
        while index < len(line):
            ch = line[index]
            if quote:
                if ch == "\\":
                    index += 2
                    continue
                if ch == quote:
                    quote = ""
                index += 1
                continue
            if ch in "\"'":
                quote = ch
                index += 1
                continue
            if ch == "#":
                break
            cleaned.append(ch)
            index += 1
        out.append("".join(cleaned))
    return "\n".join(out)


def check_scripts() -> None:
    scripts = []
    for dirpath, _dirs, files in os.walk(ROOT):
        if any(part in (".git", ".godot", "assets") for part in dirpath.split(os.sep)):
            continue
        for name in files:
            if name.endswith(".gd"):
                scripts.append(os.path.relpath(os.path.join(dirpath, name), ROOT))
    for rel in sorted(scripts):
        text = read(rel)
        lines = text.splitlines()
        # 1) خلط المسافات مع الجدولة في الإزاحة
        for number, line in enumerate(lines, 1):
            stripped = line.lstrip(" \t")
            if not stripped or stripped.startswith("#"):
                continue
            indent = line[: len(line) - len(stripped)]
            if indent.startswith(" ") and "\t" in text.splitlines()[max(0, number - 2)][:1]:
                err(f"{rel}:{number}: space indentation inside a tab-indented file")
            elif indent.startswith(" "):
                warn(f"{rel}:{number}: space indentation")
        # 2) توازن الأقواس (بعد تجاهل النصوص والتعليقات)
        depth = {"(": 0, "[": 0, "{": 0}
        pairs = {")": "(", "]": "[", "}": "{"}
        for ch in strip_noise(text):
            if ch in depth:
                depth[ch] += 1
            elif ch in pairs:
                depth[pairs[ch]] -= 1
        for open_ch, count in depth.items():
            if count != 0:
                err(f"{rel}: unbalanced \"{open_ch}\" (net {count})")
        if all(c == 0 for c in depth.values()):
            ok("brackets")
        # 3) مسارات res://
        for m in re.finditer(r'(?:preload|load)\(\s*"(res://[^"]+)"', text):
            target = res_to_fs(m.group(1))
            if not os.path.exists(os.path.join(ROOT, target)):
                err(f"{rel}: load(\"{m.group(1)}\") -> missing {target}")
            else:
                ok("res path")
        # 4) الإشارات المُصدَرة مقابل المعلنة
        declared = set(re.findall(r"^signal (\w+)", text, re.M))
        for m in re.finditer(r"(\w+)\.emit\(", text):
            name = m.group(1)
            if name in declared:
                ok("signal")
            elif name not in ("health_changed",) and not name.startswith("_"):
                # قد تكون إشارة على عقدة أخرى — تحذير فقط
                warn(f"{rel}: {name}.emit( ...) — \"{name}\" not declared in this file")
        # 6) `var x := <ternary>` — المحرّك يعطي Parse Error لأن الطرفَين Variant.
        #    هذا هو العطل الذي أسقط ui.gd في CI (Godot 4.3: "Cannot infer the type…").
        for number, line in enumerate(strip_noise(text).splitlines(), 1):
            if re.match(r"\s*var \w+\s*:=.*\bif\b.*\belse\b", line):
                err(f"{rel}:{number}: `var x := ... if ... else ...` cannot infer a type — declare it explicitly")
        # 5) class_name مكرر
        for m in re.finditer(r"^class_name (\w+)", text, re.M):
            CLASS_NAMES[m.group(1)].append(rel)


CLASS_NAMES: dict[str, list[str]] = defaultdict(list)
GROUP_ADDS: set[str] = set()
GROUP_USES: set[str] = set()


def check_groups() -> None:
    for dirpath, _dirs, files in os.walk(ROOT):
        if any(part in (".git", ".godot", "assets") for part in dirpath.split(os.sep)):
            continue
        for name in files:
            if not name.endswith(".gd"):
                continue
            rel = os.path.relpath(os.path.join(dirpath, name), ROOT)
            text = read(rel)
            for m in re.finditer(r'add_to_group\(\s*"([^"]+)"', text):
                GROUP_ADDS.add(m.group(1))
            for m in re.finditer(r'get_(?:first_node|nodes)_in_group\(\s*"([^"]+)"', text):
                GROUP_USES.add(m.group(1))
    for group in sorted(GROUP_USES):
        if group not in GROUP_ADDS:
            err(f"group \"{group}\" is queried but never added by any script")
        else:
            ok("group")
    for name, owners in CLASS_NAMES.items():
        if len(owners) > 1:
            err(f"class_name {name} declared in {owners}")


def main() -> int:
    check_scenes()
    check_scripts()
    check_groups()
    print(f"static checks passed: {checks}")
    if warnings:
        print(f"\nwarnings ({len(warnings)}):")
        for line in warnings:
            print("  ~", line)
    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for line in errors:
            print("  x", line)
        print("STATIC_CHECK_FAIL")
        return 1
    print("STATIC_CHECK_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
