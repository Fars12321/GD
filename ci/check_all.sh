#!/usr/bin/env bash
# فحص المشروع محليًا: إعادة بناء الأصول + الفحص الثابت + (إن وُجد Godot) الاختبارات بلا رأس.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== 1/3 إعادة بناء الأصول =="
bash ci/bootstrap_assets.sh

echo "== 2/3 الفحص الثابت (مشاهد، مسارات عُقد، موارد، مجموعات) =="
python3 ci/static_check.py

echo "== 3/3 اختبارات Godot بلا رأس =="
GODOT_BIN="${GODOT_BIN:-godot}"
if command -v "$GODOT_BIN" >/dev/null 2>&1; then
  "$GODOT_BIN" --headless --path . --script ci/godot_smoke.gd
  "$GODOT_BIN" --headless --path . --script ci/godot_smoke_roguelite.gd
  echo 'CHECK_ALL_PASS'
else
  echo "GODOT_SKIPPED: لم يُعثر على godot في PATH — حدّد GODOT_BIN=/path/to/godot لتشغيل اختبارات المحرّك."
  echo 'CHECK_ALL_PASS_STATIC_ONLY'
fi
