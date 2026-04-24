# 📁 Abyss & Acres — File Structure

Reflects the actual repo as of Sprint 9 (Slice 1 multiplayer plumbing).

```
res://
├── project.godot                  # autoloads: GameManager, WorldWrap,
│                                  # ThemeManager, SaveManager, AudioManager,
│                                  # NetManager
├── export_presets.cfg             # Android export, network permissions on
├── README.md
├── Master Prompt.md
│
├── png/
│   └── ui/                        # all current art lives here:
│       ├── cow.png pig.png chicken.png sheep.png   # snake heads
│       ├── segment.png
│       ├── food_apple.png food_corn.png food_carrot.png food_cabbage.png
│       ├── grass_tile.png
│       ├── butterfly_01..04.png   # ambient particles
│       ├── pollen_01..04.png
│       └── feather_poof_01..04.png
│
├── Audio/
│   └── Music/
│       └── starostin-comedy-cartoon-funny-background-music-492540.mp3
│
├── Scenes/
│   ├── Main.tscn                  # main menu host
│   ├── Game.tscn                  # gameplay arena
│   ├── Lobby.tscn                 # multiplayer lobby (Slice 1)
│   ├── Snake/
│   │   ├── SnakeHead.tscn
│   │   └── SnakeSegment.tscn
│   ├── Food/
│   │   └── FoodPellet.tscn
│   └── VFX/
│       ├── AbyssAmbient.tscn
│       ├── MeadowAmbient.tscn
│       ├── FeatherPoof.tscn
│       └── InkCloud.tscn
│
├── Scripts/
│   ├── game.gd                    # Game.tscn controller (loop, spawn, collisions)
│   ├── main_menu.gd               # Main.tscn controller (buttons, mode/skin row)
│   │
│   ├── Core/
│   │   ├── game_manager.gd        # autoload — score, mode enum, run state
│   │   ├── object_pool.gd         # generic pool (food, segments)
│   │   ├── world_wrap.gd          # autoload — torus math
│   │   └── world_border.gd        # arena border / shrink helper
│   │
│   ├── Snake/
│   │   ├── snake_controller.gd    # head movement, growth, powerups, death
│   │   ├── body_manager.gd        # ring buffer + segment placement
│   │   ├── player_input.gd        # joystick → heading
│   │   ├── ai_brain.gd            # bot FSM + 5 personalities
│   │   └── ghost_renderer.gd      # edge ghost copies
│   │
│   ├── Powerups/
│   │   └── powerup.gd             # pickup entity (4 kinds)
│   │
│   ├── Theme/
│   │   ├── theme_manager.gd       # autoload — active theme accessor
│   │   └── theme_data.gd          # Resource per theme
│   │
│   ├── UI/
│   │   ├── hud.gd                 # score, mode label, powerup panel
│   │   ├── minimap.gd
│   │   └── virtual_joystick.gd
│   │
│   ├── Audio/
│   │   └── audio_manager.gd       # autoload — threaded MP3 + procedural fallback
│   │
│   ├── Data/
│   │   └── save_manager.gd        # autoload — JSON at user://save_data.json
│   │
│   ├── VFX/
│   │   ├── ambient_particles.gd
│   │   ├── death_vfx.gd
│   │   └── snake_lighting.gd
│   │
│   └── Net/                       # NEW — multiplayer
│       ├── net_manager.gd         # autoload — ENet host/join/RPC/nicknames
│       ├── lan_discovery.gd       # UDP broadcast/listen on port 8911
│       └── lobby.gd               # Lobby.tscn controller
│
├── Shaders/
│   ├── grass_wind.gdshader
│   ├── water_distortion.gdshader
│   └── chromatic_aberration.gdshader
│
├── Tests/                         # GDScript unit tests
│   ├── Core/
│   │   ├── test_object_pool.gd
│   │   └── test_world_wrap.gd
│   ├── Data/
│   │   └── test_save_manager.gd
│   ├── Snake/
│   │   ├── test_ai_brain.gd
│   │   ├── test_body_manager.gd
│   │   └── test_snake_controller.gd
│   └── Theme/
│       └── test_theme_manager.gd
│
├── build/
│   └── AbyssAcres.apk             # latest debug build (gitignored)
│
└── Docs/
    ├── 01_Project_Roadmap.md
    ├── 02_File_Structure.md       # this file
    ├── 03_World_Wrap_Plan.md
    ├── 04_Deep_Sea_Lighting_Stack.md
    ├── 05_Design_Plan.md
    ├── 06_UI_Art_Prompts.md
    ├── 07_Unit_Tests.md
    └── 08_Online_Plan.md
```

## Autoloads (project.godot order)

1. `GameManager` — `res://Scripts/Core/game_manager.gd`
2. `WorldWrap` — `res://Scripts/Core/world_wrap.gd`
3. `ThemeManager` — `res://Scripts/Theme/theme_manager.gd`
4. `SaveManager` — `res://Scripts/Data/save_manager.gd`
5. `AudioManager` — `res://Scripts/Audio/audio_manager.gd`
6. `NetManager` — `res://Scripts/Net/net_manager.gd`

## Network ports

- **8910** — game traffic (ENet/UDP)
- **8911** — LAN discovery beacon (UDP broadcast)
# 📁 Abyss & Acres — File Structure

```
res://
├── Assets/
│   ├── Textures/
│   │   ├── Meadow/          # grass tile, crop sprites, animal heads, segment, VFX
│   │   └── UI/              # menu bg, joystick, boost button, score panel, game over
│   ├── Audio/
│   │   ├── SFX/
│   │   └── Music/
│   └── Fonts/
├── Scenes/
│   ├── Main.tscn             # entry point / menu
│   ├── Game.tscn              # gameplay arena
│   ├── UI/
│   │   ├── HUD.tscn          # joystick, boost, score
│   │   ├── MainMenu.tscn
│   │   └── SkinSelect.tscn
│   ├── Snake/
│   │   ├── SnakeHead.tscn
│   │   └── SnakeSegment.tscn
│   └── Food/
│       └── FoodPellet.tscn
├── Scripts/
│   ├── Core/
│   │   ├── game_manager.gd
│   │   ├── object_pool.gd
│   │   └── world_wrap.gd     # torus math helpers
│   ├── Snake/
│   │   ├── snake_controller.gd   # shared base (head movement, growth)
│   │   ├── player_input.gd       # joystick → direction
│   │   ├── ai_brain.gd           # bot steering
│   │   └── body_manager.gd       # position-history buffer & segment placement
│   ├── Theme/
│   │   ├── theme_manager.gd      # swap sprites, shaders, particles at runtime
│   │   └── theme_data.gd         # Resource class per theme
│   ├── UI/
│   │   ├── hud.gd
│   │   └── virtual_joystick.gd
│   └── Data/
│       └── save_manager.gd       # JSON read/write
├── Shaders/
│   ├── grass_wind.gdshader
│   ├── water_distortion.gdshader
│   └── chromatic_aberration.gdshader
└── Resources/
    └── ThemeMeadow.tres
```
