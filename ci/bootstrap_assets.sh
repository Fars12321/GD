#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$ROOT/.ci_asset_extract"
rm -rf "$TMP"; mkdir -p "$TMP"

unpack() {
  local pattern="$1" zip out
  zip=$(find "$ROOT" -maxdepth 1 -type f -name "$pattern" -print -quit)
  [[ -n "$zip" ]] || { echo "Missing source asset archive: $pattern" >&2; exit 1; }
  out="$TMP/$(basename "$zip" .zip)"; mkdir -p "$out"; unzip -q "$zip" -d "$out"; echo "$out"
}
copy_named() {
  local source_root="$1" name="$2" destination="$3" found
  found=$(find "$source_root" -type f -name "$name" -print -quit)
  [[ -n "$found" ]] || { echo "Missing asset inside archive: $name" >&2; exit 1; }
  mkdir -p "$(dirname "$ROOT/$destination")"; cp "$found" "$ROOT/$destination"
}

NATURE=$(unpack 'KayKit_Forest_Nature_Pack_1.0_FREE.zip')
SKELETONS=$(unpack 'KayKit-Character-Pack-Skeletons-1.0-main.zip')
CASTLE=$(unpack 'kenney_castle-kit.zip')
TOWN=$(unpack 'kenney_fantasy-town-kit_2.0.zip')
HEX=$(unpack 'kenney_hexagon-kit.zip')
IMPACT=$(unpack 'kenney_impact-sounds.zip')
UIAUDIO=$(unpack 'kenney_ui-audio.zip')
CARTO=$(unpack 'kenney_cartography-pack.zip')

for name in Tree_1_A_Color1.gltf Tree_1_A_Color1.bin Tree_2_A_Color1.gltf Tree_2_A_Color1.bin Rock_1_A_Color1.gltf Rock_1_A_Color1.bin Rock_2_A_Color1.gltf Rock_2_A_Color1.bin forest_texture.png; do copy_named "$NATURE" "$name" "assets/models/nature/$name"; done
copy_named "$SKELETONS" 'Skeleton_Warrior.glb' 'assets/characters/Skeleton_Warrior.glb'
copy_named "$SKELETONS" 'LICENSE.txt' 'assets/characters/KayKit-Skeletons-LICENSE.txt'
for name in gate.glb rocks-large.glb rocks-small.glb tower-slant-roof.glb tower-square-base.glb tower-square-mid-door.glb wall-corner.glb wall-doorway.glb wall-half.glb wall.glb; do copy_named "$CASTLE" "$name" "assets/models/castle-kit/$name"; done
for name in cart.glb chimney.glb fence.glb; do copy_named "$TOWN" "$name" "assets/models/fantasy-town-kit/$name"; done
for name in unit-house.glb unit-tower.glb unit-tree.glb unit-wall-tower.glb; do copy_named "$HEX" "$name" "assets/models/hexagon-kit/$name"; done
for name in footstep_grass_000.ogg impactMining_000.ogg impactMining_001.ogg impactWood_light_000.ogg impactWood_medium_000.ogg; do copy_named "$IMPACT" "$name" "assets/audio/impact/$name"; done
for name in click1.ogg rollover1.ogg switch1.ogg; do copy_named "$UIAUDIO" "$name" "assets/audio/ui/$name"; done

copy_named "$CARTO" 'parchmentBasic.png' 'assets/textures/cartography/parchmentBasic.png'
copy_named "$CASTLE" 'colormap.png' 'assets/models/castle-kit/Textures/colormap.png'
copy_named "$TOWN" 'colormap.png' 'assets/models/fantasy-town-kit/Textures/colormap.png'
copy_named "$HEX" 'colormap.png' 'assets/models/hexagon-kit/Textures/colormap.png'

rm -rf "$TMP"
echo 'ASSET_BOOTSTRAP_PASS'
