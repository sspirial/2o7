# 2o7 — Milestone M0 & M1 Completion Report

*A narrative matatu game about Kenya 2007–08 · Prototype Build*

## Summary of Completed Work

Milestones **M0 (Foundation)** and **M1 (Playable Prototype System)** are now completely set up in [`dev/2o7`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7).

---

## Deliverables Inventory

### 1. Project Configuration & Scaffolding
- [`project.godot`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/project.godot): Godot 4.3 project setup, 720×1280 mobile portrait, Autoloads configured, touch emulation enabled.
- [`.gitignore`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/.gitignore): Godot 4 ignore rules (.godot, builds, exports).
- [`export_presets.cfg`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/export_presets.cfg): Android export configuration stub.
- [`README.md`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/README.md): Project overview and setup guide.

### 2. Core Systems (GDScript)
- [`scripts/game_state.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/game_state.gd): Global singleton tracking player name, gender, story flags (`matatu_choice`, `kiosk_choice`), NPC trust (`mama_achieng`, `jabali`, `mum`), and SMS inbox.
- [`scripts/save_manager.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/save_manager.gd): Local JSON persistence (`user://save_data.json`) with versioning.
- [`scripts/shusha_manager.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/shusha_manager.gd): Ethics Charter E6 safety feature. Global pause, skip scene with summary, and verified support hotlines (Red Cross 1199, Childline 116, Befrienders).
- [`scripts/scene_router.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/scene_router.gd): Flow coordinator managing scene transitions with smooth fade-in/fade-out overlays.
- [`scripts/dialogue_runner.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/dialogue_runner.gd): Dynamic narrative parser handling JSON dialogue nodes, choices, effects, trust mutations, branch nodes, name entry, and Sheng/Kiswahili glosses.
- [`scripts/phone_manager.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scripts/phone_manager.gd): Evaluates narrative decisions and delivers reactive SMS from Mum, Jabali, and Mama Achieng'.

### 3. Narrative Data (99 Nodes)
- [`data/characters/characters.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/characters/characters.json): Cast definitions for Player, Jabali, Mama Achieng', and Mum.
- [`data/chapters/prologue.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/chapters/prologue.json): Name selection, morning estate atmosphere, Mum's fare handoff.
- [`data/chapters/ch1_matatu_ride.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/chapters/ch1_matatu_ride.json): Boarding *Msafiri*, Genge soundtrack, 3-way branching debate on M-Pesa.
- [`data/chapters/ch1_kiosk.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/chapters/ch1_kiosk.json): Mama Achieng's kiosk registration, 2-way choice (help vs tease), first M-Pesa transaction.
- [`data/chapters/ch1_phone.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/chapters/ch1_phone.json): Reactive SMS inbox events.
- [`data/chapters/end_screen.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/chapters/end_screen.json): Choice recap and "Kila stage ina stori" epilogue.
- [`data/rumours/rumour_schema.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/rumours/rumour_schema.json): Schema and tutorial rumour R01.
- [`data/archive/archive_schema.json`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/data/archive/archive_schema.json): Factual cards for M-Pesa launch and Matatu culture with confidence ratings.

### 4. Visuals, Art & UI
- **Theme & Palette**: [`assets/ui/theme_2o7.tres`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/ui/theme_2o7.tres) and [`assets/ui/palettes.gd`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/ui/palettes.gd).
- **Backgrounds**: [`bg_home.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/backgrounds/bg_home.tscn), [`bg_stage7.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/backgrounds/bg_stage7.tscn), [`bg_matatu_interior.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/backgrounds/bg_matatu_interior.tscn) (with animated vehicle bounce), [`bg_kiosk.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/backgrounds/bg_kiosk.tscn), [`bg_estate.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/backgrounds/bg_estate.tscn).
- **Portraits**: [`portrait_player.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/characters/portrait_player.tscn), [`portrait_jabali.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/characters/portrait_jabali.tscn), [`portrait_mama_achieng.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/characters/portrait_mama_achieng.tscn), [`portrait_mum.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/assets/characters/portrait_mum.tscn).
- **Nokia Phone Experience**: [`phone.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scenes/phone/phone.tscn), [`sms_inbox.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scenes/phone/sms_inbox.tscn), with LCD green screen and message viewer.
- **Safety**: [`pause_shusha.tscn`](file:///c:/Users/emmun/OneDrive/Documents/dev/2o7/scenes/menus/pause_shusha.tscn) with quick-access `ShushaBtn` on interactive scenes.
