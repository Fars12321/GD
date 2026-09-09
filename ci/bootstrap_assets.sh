#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$ROOT/.ci_asset_extract"
rm -rf "$TMP"
mkdir -p "$TMP"

unpack() {
  local pattern="$1"
  local zip
  zip=$(find "$ROOT" -maxdepth 1 -type f -name "$pattern" -print -quit)
  if [[ -z "$zip" ]]; then
    echo "Missing source asset archive: $pattern" >&2
    exit 1
  fi
  local out="$TMP/$(basename "$zip" .zip)"
  mkdir -p "$out"
  unzip -q "$zip" -d "$out"
  echo "$out"
}

copy_named() {
  local source_root="$1"; local name="$2"; local destination="$3"
  local found
  found=$(find "$source_root" -type f -name "$name" -print -quit)
  if [[ -z "$found" ]]; then
    echo "Missing asset inside archive: $name" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$ROOT/$destination")"
  cp "$found" "$ROOT/$destination"
}

NATURE=$(unpack 'KayKit_Forest_Nature_Pack_1.0_FREE.zip')
CASTLE=$(unpack 'kenney_castle-kit.zip')
TOWN=$(unpack 'kenney_fantasy-town-kit_2.0.zip')
HEX=$(unpack 'kenney_hexagon-kit.zip')
IMPACT=$(unpack 'kenney_impact-sounds.zip')
UIAUDIO=$(unpack 'kenney_ui-audio.zip')
CARTO=$(unpack 'kenney_cartography-pack.zip')

copy_named "$NATURE" 'Tree_1_A_Color1.gltf' 'assets/models/nature/Tree_1_A_Color1.gltf'
copy_named "$NATURE" 'Tree_1_A_Color1.bin'  'assets/models/nature/Tree_1_A_Color1.bin'
copy_named "$NATURE" 'Tree_2_A_Color1.gltf' 'assets/models/nature/Tree_2_A_Color1.gltf'
copy_named "$NATURE" 'Tree_2_A_Color1.bin'  'assets/models/nature/Tree_2_A_Color1.bin'
copy_named "$NATURE" 'Rock_1_A_Color1.gltf' 'assets/models/nature/Rock_1_A_Color1.gltf'
copy_named "$NATURE" 'Rock_1_A_Color1.bin'  'assets/models/nature/Rock_1_A_Color1.bin'
copy_named "$NATURE" 'Rock_2_A_Color1.gltf' 'assets/models/nature/Rock_2_A_Color1.gltf'
copy_named "$NATURE" 'Rock_2_A_Color1.bin'  'assets/models/nature/Rock_2_A_Color1.bin'
copy_named "$NATURE" 'forest_texture.png' 'assets/models/nature/forest_texture.png'

for name in gate.glb rocks-large.glb rocks-small.glb tower-slant-roof.glb tower-square-base.glb tower-square-mid-door.glb wall-corner.glb wall-doorway.glb wall-half.glb wall.glb; do
  copy_named "$CASTLE" "$name" "assets/models/castle-kit/$name"
done

for name in cart.glb chimney.glb fence.glb; do
  copy_named "$TOWN" "$name" "assets/models/fantasy-town-kit/$name"
done

for name in unit-house.glb unit-tower.glb unit-tree.glb unit-wall-tower.glb; do
  copy_named "$HEX" "$name" "assets/models/hexagon-kit/$name"
done

for name in footstep_grass_000.ogg impactMining_000.ogg impactMining_001.ogg impactWood_light_000.ogg impactWood_medium_000.ogg; do
  copy_named "$IMPACT" "$name" "assets/audio/impact/$name"
done

for name in click1.ogg rollover1.ogg switch1.ogg; do
  copy_named "$UIAUDIO" "$name" "assets/audio/ui/$name"
done

copy_named "$CARTO" 'parchmentBasic.png' 'assets/textures/cartography/parchmentBasic.png'

rm -rf "$TMP"
echo 'ASSET_BOOTSTRAP_PASS'
