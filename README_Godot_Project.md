# Village Defense — Phase 3.1

Godot 4 mobile-compatible prototype for the kingdom-defense game.

Current phase includes:
- top-down/isometric player movement with virtual joystick and keyboard fallback
- resource gathering (wood/stone)
- mobile HUD and build menu
- grid-snapped wall/tower placement with ghost preview
- collision validation and resource spending
- hardened camera smoothing and mobile-friendly Compatibility renderer

The GitHub CI runner reconstructs the required binary assets from the asset ZIPs already stored in this repository before importing/running the Godot project.

**Phase boundary:** this remains Phase 3.1. Day/night, enemies and navigation belong to Phase 4 and are intentionally not enabled here.
