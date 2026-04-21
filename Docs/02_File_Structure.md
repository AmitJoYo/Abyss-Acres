# 📁 Abyss & Acres — File Structure

```
res://
├── Assets/
│   ├── Textures/
│   │   ├── Meadow/          # grass tile, crop sprites, animal heads
│   │   └── Abyss/           # gradient bg, plankton, bioluminescent sprites
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
    ├── ThemeMeadow.tres
    └── ThemeAbyss.tres
```
