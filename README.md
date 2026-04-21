# 🐍 Abyss & Acres

An infinite, wrapping Snake.io game built in **Godot 4.x (GDScript)** for Android. Premium, ad-free, offline-first.

## Overview

Scale between two hand-crafted themes:
- **The Meadow** — Farm animals, crops, wind-swaying grass, butterflies
- **The Abyss** — Bioluminescent deep-sea creatures, glowing plankton, water distortion

## Features

- Smooth, non-grid snake movement via position-history interpolation
- Torus-wrapping infinite world (no walls, seamless edge crossing)
- AI bot snakes with wander/chase/avoid behaviors
- Object-pooled segments & food for consistent 60 FPS on mid-range Android
- Runtime theme switching (sprites, shaders, particles, audio)
- Virtual joystick + boost button controls
- Local high scores & skin unlocks (JSON, no server required)

## Tech Stack

| Component | Choice |
|---|---|
| Engine | Godot 4.x |
| Language | GDScript |
| Target | Android (ARM64), min API 24 |
| Rendering | Compatibility renderer (Mobile) |
| Lighting | PointLight2D (Abyss), unlit (Meadow) |
| Particles | GPUParticles2D |
| Persistence | JSON via FileAccess |

## Project Structure

```
res://
├── Assets/          # Textures, Audio, Fonts
├── Scenes/          # .tscn files (Game, UI, Snake, Food)
├── Scripts/         # GDScript organized by domain
├── Shaders/         # .gdshader files
└── Resources/       # .tres theme data
```

See [Docs/02_File_Structure.md](Docs/02_File_Structure.md) for the full hierarchy.

## Building

1. Open the project in Godot 4.x
2. Install Android export templates: `Editor → Manage Export Templates`
3. Configure Android keystore in `Project → Export → Android`
4. Export: `Project → Export → Android → Export Project`

## Documentation

| Doc | Description |
|---|---|
| [01_Project_Roadmap.md](Docs/01_Project_Roadmap.md) | Sprint plan |
| [02_File_Structure.md](Docs/02_File_Structure.md) | Folder hierarchy |
| [03_World_Wrap_Plan.md](Docs/03_World_Wrap_Plan.md) | Torus math |
| [04_Deep_Sea_Lighting_Stack.md](Docs/04_Deep_Sea_Lighting_Stack.md) | Lighting tech |
| [05_Design_Plan.md](Docs/05_Design_Plan.md) | Game design document |
| [06_UI_Art_Prompts.md](Docs/06_UI_Art_Prompts.md) | AI image-gen prompts |
| [07_Unit_Tests.md](Docs/07_Unit_Tests.md) | Test plan & cases |

## License

Private — All rights reserved.
