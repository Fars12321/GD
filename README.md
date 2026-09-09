# Village Defense — Phase 3 Review Build

## Grid Building System

This branch is the Phase 3 review build on top of the approved Phase 2 resource/inventory foundation. Day/night, enemy waves, combat and navigation are intentionally not included.

Implemented:
- `scripts/building_manager.gd`: 2m grid snapping, preview/placement state, touch/mouse movement, green/red transparent preview, overlap validation on building collision layer, resource validation, confirmation/cancel flow, and build audio.
- `scenes/buildings/Wall.tscn`: real castle-kit wall asset with `StaticBody3D` + `CollisionShape3D` on building layer 4.
- `scenes/buildings/Tower.tscn`: real castle-kit tower assets with `StaticBody3D` + `CollisionShape3D` on building layer 4.
- `scripts/mobile_ui.gd` + `scenes/ui.tscn`: mobile build menu, 10-wood wall, 10-stone tower, confirm/cancel controls, placement status, resource counters and contextual gathering UI.
- `scripts/player.gd`: existing Phase 2 inventory plus `spend_resources()` used by confirmed construction.
- `scenes/Main.tscn`: existing kingdom presentation, resources, touch controls and BuildingManager remain connected.

## Test flow
1. Gather until you have at least 10 wood or 10 stone.
2. Open **بناء**.
3. Choose **سور — 10 خشب** or **برج دفاعي — 10 حجر**.
4. Move the translucent preview by touch/mouse; it snaps to 2m cells.
5. Green means the cell is buildable and affordable; red means blocked or unaffordable.
6. Confirm to spend resources and create the solid building; cancel returns to normal play.
7. Try placing another building on an occupied cell to verify the invalid state.

Phase 4 systems are deliberately not included in this review build.
