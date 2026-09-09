# Village Defense — Phase 2 Review Build

## Resource Gathering System & Mobile UI

This branch is intentionally frozen at **Phase 2**. It does not include the Phase 3 building system.

Implemented:
- `scenes/resource_node.tscn` with `Area3D`, interaction `CollisionShape3D`, visual `MeshInstance3D`, and 3D gather audio.
- `scripts/resource_node.gd` with `ResourceType { WOOD, STONE }`, node capacity, collection signal, sound, shake, and depletion/freeing.
- `scripts/player.gd` with `wood_count`, `stone_count`, `resources_changed`, nearest-resource detection, and `gather_nearest()`.
- `scenes/ui.tscn` + `scripts/mobile_ui.gd` with `Wood: 0 | Stone: 0` counters and contextual Gather button.
- `scenes/Main.tscn` with four real nature resource instances using the supplied assets.
- Touch joystick and keyboard movement remain available for testing.

## Test flow
1. Start with `Wood: 0` and `Stone: 0`.
2. Walk toward a tree or rock.
3. The contextual Gather button appears.
4. Press Gather repeatedly; the matching counter increments.
5. The resource shakes on each collection and disappears after its capacity reaches zero.
6. Move away; the Gather button hides automatically.

Phase 3 is deliberately not included in this review build.
