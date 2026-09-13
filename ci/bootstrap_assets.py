#!/usr/bin/env python3
"""إعادة بناء مجلد assets/ من ملفات ZIP داخل المستودع — نسخة Python صافية.

مرآة لـ ci/bootstrap_assets.sh، لكنها تعمل على ويندوز دون bash أو unzip.
كل ما تحتاجه Python 3.8+.

الاستخدام:  python ci/bootstrap_assets.py
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

NATURE_FILES = [
    "Tree_1_A_Color1.gltf", "Tree_1_A_Color1.bin",
    "Tree_2_A_Color1.gltf", "Tree_2_A_Color1.bin",
    "Rock_1_A_Color1.gltf", "Rock_1_A_Color1.bin",
    "Rock_2_A_Color1.gltf", "Rock_2_A_Color1.bin",
    "forest_texture.png",
]
CASTLE_FILES = [
    "gate.glb", "rocks-large.glb", "rocks-small.glb", "tower-slant-roof.glb",
    "tower-square-base.glb", "tower-square-mid-door.glb", "wall-corner.glb",
    "wall-doorway.glb", "wall-half.glb", "wall.glb",
]
TOWN_FILES = ["cart.glb", "chimney.glb", "fence.glb"]
HEX_FILES = ["unit-house.glb", "unit-tower.glb", "unit-tree.glb", "unit-wall-tower.glb"]
IMPACT_FILES = [
    "footstep_grass_000.ogg", "impactMining_000.ogg", "impactMining_001.ogg",
    "impactWood_light_000.ogg", "impactWood_medium_000.ogg",
]
UI_AUDIO_FILES = ["click1.ogg", "rollover1.ogg", "switch1.ogg"]


def find_archive(pattern: str) -> str:
    matches = sorted(name for name in os.listdir(ROOT)
                     if name == pattern and os.path.isfile(os.path.join(ROOT, name)))
    if not matches:
        sys.exit(f"Missing source asset archive: {pattern}")
    return os.path.join(ROOT, matches[0])


def extract(archive: str, workdir: str) -> str:
    """يفكّ الأرشيف داخل مجلد عمل مؤقت ويعيد مساره."""
    target = os.path.join(workdir, os.path.splitext(os.path.basename(archive))[0])
    os.makedirs(target, exist_ok=True)
    with zipfile.ZipFile(archive) as handle:
        for member in handle.namelist():
            # حماية من مسارات تخرج عن مجلد الهدف (zip slip).
            destination = os.path.realpath(os.path.join(target, member))
            if not destination.startswith(os.path.realpath(target) + os.sep) and destination != os.path.realpath(target):
                sys.exit(f"Unsafe path inside archive {archive}: {member}")
        handle.extractall(target)
    return target


def copy_named(source_root: str, name: str, destination: str) -> None:
    """ينسخ أول ملف يطابق اسمه `name` داخل `source_root` إلى `destination`."""
    candidates = []
    for dirpath, _dirs, files in os.walk(source_root):
        for file in files:
            if file == name:
                candidates.append(os.path.join(dirpath, file))
    if not candidates:
        sys.exit(f"Missing asset inside archive: {name}")
    found = sorted(candidates)[0]
    target = os.path.join(ROOT, destination)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    shutil.copyfile(found, target)


def copy_all(source_root: str, names: list, prefix: str) -> None:
    for name in names:
        copy_named(source_root, name, f"{prefix}{name}")


def main() -> int:
    workdir = tempfile.mkdtemp(prefix="gd_assets_")
    try:
        nature = extract(find_archive("KayKit_Forest_Nature_Pack_1.0_FREE.zip"), workdir)
        skeletons = extract(find_archive("KayKit-Character-Pack-Skeletons-1.0-main.zip"), workdir)
        castle = extract(find_archive("kenney_castle-kit.zip"), workdir)
        town = extract(find_archive("kenney_fantasy-town-kit_2.0.zip"), workdir)
        hexagon = extract(find_archive("kenney_hexagon-kit.zip"), workdir)
        impact = extract(find_archive("kenney_impact-sounds.zip"), workdir)
        ui_audio = extract(find_archive("kenney_ui-audio.zip"), workdir)
        cartography = extract(find_archive("kenney_cartography-pack.zip"), workdir)

        copy_all(nature, NATURE_FILES, "assets/models/nature/")
        copy_named(skeletons, "Skeleton_Warrior.glb", "assets/characters/Skeleton_Warrior.glb")
        copy_named(skeletons, "LICENSE.txt", "assets/characters/KayKit-Skeletons-LICENSE.txt")
        copy_all(castle, CASTLE_FILES, "assets/models/castle-kit/")
        copy_all(town, TOWN_FILES, "assets/models/fantasy-town-kit/")
        copy_all(hexagon, HEX_FILES, "assets/models/hexagon-kit/")
        copy_all(impact, IMPACT_FILES, "assets/audio/impact/")
        copy_all(ui_audio, UI_AUDIO_FILES, "assets/audio/ui/")

        copy_named(cartography, "parchmentBasic.png", "assets/textures/cartography/parchmentBasic.png")
        copy_named(castle, "colormap.png", "assets/models/castle-kit/Textures/colormap.png")
        copy_named(town, "colormap.png", "assets/models/fantasy-town-kit/Textures/colormap.png")
        copy_named(hexagon, "colormap.png", "assets/models/hexagon-kit/Textures/colormap.png")
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    print("ASSET_BOOTSTRAP_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
