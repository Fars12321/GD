#!/usr/bin/env python3
"""
أداة استخراج أصول المشروع من ملفات ZIP المرفوعة.
تستخرج كل حزمة إلى assets/<folder_name>/ مع إزالة المجلد الجذري الزائد
الموجود داخل كل ZIP (strip first top-level component).
"""
import zipfile
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIPS = os.path.join(ROOT, "*.zip")
DEST = os.path.join(ROOT, "assets")

# تعيين: اسم الـ ZIP -> اسم مجلد الاستخراج داخل assets/
PACK_MAP = {
    "KayKit-Character-Pack-Adventures-1.0-672074b73ba276876a19e8816ecdc5241817ab47.zip": "kaykit_character_pack_adventures",
    "KayKit-Character-Pack-Skeletons-1.0-main.zip": "kaykit_character_pack_skeletons",
    "KayKit_Adventurers_2.0_FREE.zip": "kaykit_adventurers_2",
    "KayKit_Character_Animations_1.1.zip": "kaykit_character_animations",
    "KayKit_Forest_Nature_Pack_1.0_FREE.zip": "kaykit_forest_nature",
    "KayKit_Skeletons_1.1_FREE.zip": "kaykit_skeletons_1",
    "kenney_cartography-pack.zip": "kenney_cartography",
    "kenney_castle-kit.zip": "kenney_castle_kit",
    "kenney_fantasy-town-kit_2.0.zip": "kenney_fantasy_town",
    "kenney_hexagon-kit.zip": "kenney_hexagon",
    "kenney_impact-sounds.zip": "kenney_impact_sounds",
    "kenney_mini-forest_1.0.zip": "kenney_mini_forest",
    "kenney_ui-audio.zip": "kenney_ui_audio",
}


def strip_top(name: str) -> str:
    """يزيل أول مكوّن من المسار داخل الـ ZIP (المجلد الجذري للحزمة)."""
    parts = name.split("/")
    return "/".join(parts[1:]) if len(parts) > 1 else ""


def extract(zip_path: str, folder: str) -> None:
    target = os.path.join(DEST, folder)
    os.makedirs(target, exist_ok=True)
    with zipfile.ZipFile(zip_path) as zf:
        for info in zf.infolist():
            # تخطّي ملفات ماك الزائدة والدلائل
            rel = strip_top(info.filename)
            if not rel or rel.startswith("__MACOSX") or info.is_dir():
                continue
            out_path = os.path.join(target, rel)
            # حماية من المسارات الخارجة عن المجلد
            if not os.path.abspath(out_path).startswith(os.path.abspath(target)):
                continue
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            with zf.open(info) as src, open(out_path, "wb") as dst:
                dst.write(src.read())
    print(f"OK: {zip_path} -> assets/{folder}  ({len(os.listdir(target))} entries)")


def main() -> None:
    if not os.path.isdir(ZIPS_dir := os.path.dirname(ZIPS)):
        sys.exit("No *.zip found at repo root.")
    zips = sorted(f for f in os.listdir(os.path.dirname(ZIPS)) if f.endswith(".zip"))
    done = 0
    for z in zips:
        folder = PACK_MAP.get(z)
        if not folder:
            print(f"SKIP (غير معرّف في PACK_MAP): {z}")
            continue
        extract(os.path.join(os.path.dirname(ZIPS), z), folder)
        done += 1
    print(f"\nExtracted {done} packs into {DEST}")


if __name__ == "__main__":
    main()
