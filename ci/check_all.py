#!/usr/bin/env python3
"""فحص المشروع بالكامل — يعمل على ويندوز/ماك/لينكس دون bash.

  1) إعادة بناء assets/ من ملفات ZIP
  2) الفحص الثابت (مشاهد، مسارات عُقد، موارد، مجموعات)
  3) اختبارات Godot بلا رأس — إن وُجد المحرّك

الاستخدام:
  python ci/check_all.py
  GODOT_BIN=/path/to/godot python ci/check_all.py        (لينكس/ماك)
  set GODOT_BIN=C:\\godot\\Godot_v4.3-stable_win64.exe    (ويندوز)
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT_CANDIDATES = ["godot", "godot4", "godot-headless", "Godot_v4.3-stable_win64.exe"]


def step(title: str) -> None:
    print(f"\n=== {title} ===", flush=True)


def run(command: list, timeout: int = 180) -> int:
    print("$", " ".join(command), flush=True)
    try:
        return subprocess.call(command, cwd=ROOT, timeout=timeout)
    except subprocess.TimeoutExpired:
        print(f"TIMEOUT after {timeout}s")
        return 124


def find_godot() -> str | None:
    explicit = os.environ.get("GODOT_BIN")
    if explicit:
        if os.path.isfile(explicit) or shutil.which(explicit):
            return explicit
        print(f"GODOT_BIN={explicit} غير موجود")
        return None
    for name in GODOT_CANDIDATES:
        found = shutil.which(name)
        if found:
            return found
    return None


def main() -> int:
    python = sys.executable or "python3"

    step("1/3 إعادة بناء الأصول")
    if run([python, os.path.join("ci", "bootstrap_assets.py")]) != 0:
        print("BOOTSTRAP_FAIL")
        return 1

    step("2/3 الفحص الثابت")
    if run([python, os.path.join("ci", "static_check.py")]) != 0:
        return 1

    step("3/3 اختبارات Godot بلا رأس")
    godot = find_godot()
    if godot is None:
        print("GODOT_SKIPPED: لم يُعثر على محرّك Godot.")
        print("  نزّل Godot 4.3 من https://godotengine.org/download/archive/4.3-stable/")
        print("  ثم حدّد GODOT_BIN وأعد التشغيل.")
        print("CHECK_ALL_PASS_STATIC_ONLY")
        return 0

    failures = 0
    for script in ("ci/godot_smoke.gd", "ci/godot_smoke_roguelite.gd"):
        if run([godot, "--headless", "--path", ".", "--script", script], timeout=120) != 0:
            print(f"FAILED: {script}")
            failures += 1

    if failures:
        print(f"CHECK_ALL_FAIL ({failures} test script(s) failed)")
        return 1
    print("CHECK_ALL_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
