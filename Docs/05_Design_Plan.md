# 🎮 Abyss & Acres — Game Design Plan

## 1. Game Loop

```
Main Menu → Select Theme/Skin → Spawn into World → Eat → Grow → Avoid/Kill → Die → Score Screen → Retry
```

### Core Loop (per frame)
1. Read joystick input (or AI decision)
2. Move head in direction at current speed
3. Push head position to history buffer
4. Update each body segment from buffer (wrap-aware)
5. Check head-to-body collisions (all snakes, wrapped distance)
6. Check head-to-food collisions → grow + score
7. Cull off-screen lights, spawn/despawn food via object pool

## 2. Player Snake

| Attribute | Value |
|---|---|
| Base speed | 200 px/s |
| Boost speed | 350 px/s |
| Boost cost | Lose 1 segment every 0.8s while boosting |
| Turn rate | 4.0 rad/s (smooth, not instant) |
| Segment spacing | 18 px (in history buffer indices) |
| Starting segments | 5 |
| Max segments | 500 (performance cap) |

## 3. Growth & Scoring

| Food Type | Segments Gained | Score |
|---|---|---|
| Small (Apple / Plankton) | +1 | +10 |
| Medium (Corn / Shrimp) | +2 | +25 |
| Death drop (per segment of dead snake) | +1 | +5 |

- **Length multiplier:** Score display = `segments × 10` (shown as "length")
- **Kill bonus:** +100 per kill (when your body causes another head's collision)

## 4. AI Bot Behavior

### States (State Machine)
| State | Behavior |
|---|---|
| **Wander** | Pick random direction, slight curve. Switch to Chase if food within 300px. |
| **Chase** | Steer toward nearest food. Switch to Avoid if another head within 150px. |
| **Avoid** | Steer perpendicular to threat direction for 1s, then resume Wander. |
| **Aggressive** (large bots) | Attempt to circle smaller snakes. Triggered when bot has 3× target's length. |

### Bot Spawning
- Start: 5 bots
- Max: 15 bots on-screen (world can hold more, but cull distant ones)
- Respawn: When a bot dies, respawn a new one at a random edge after 3s
- Difficulty ramp: Bot speed increases by 5% every 60s of player survival

## 5. Death & Respawn

1. Head collides with any body segment (own or other snake's)
2. Snake "dissolves" — each segment becomes a food pellet at its position
3. Death VFX plays (feathers / ink cloud)
4. **Player death:** Show score screen → retry or menu
5. **Bot death:** Segments become food, bot respawns after delay

## 6. World Layout

- World size: 4000 × 4000 px (torus-wrapped)
- Viewport: ~800 × 600 px (scales with device)
- Food density: ~120 items at any time (object pooled)
- Food respawn: When eaten, a new food spawns at a random position after 1–3s

## 7. Theme Data Structure

```gdscript
class_name ThemeData extends Resource

@export var theme_name: String
@export var background_texture: Texture2D
@export var background_shader: Shader
@export var head_sprites: Array[Texture2D]      # per skin
@export var segment_sprite: Texture2D
@export var food_sprites: Array[Texture2D]       # small, medium
@export var food_names: Array[String]
@export var death_particle: PackedScene
@export var ambient_particle: PackedScene
@export var use_lighting: bool                    # true for Abyss only
@export var segment_modulate: Color
@export var music_track: AudioStream
@export var eat_sfx: AudioStream
@export var death_sfx: AudioStream
@export var boost_sfx: AudioStream
```

## 8. Camera

- Smooth follow (lerp 0.08) on player head
- Slight zoom-out as snake grows: `zoom = lerp(1.0, 0.7, segments / 300.0)`
- Screen shake on death (intensity 8px, duration 0.3s)

## 9. Skin System

| Theme | Skins (Head) | Unlock Condition |
|---|---|---|
| Meadow | Cow (default), Pig, Chicken, Sheep | Pig: reach 50 length. Chicken: 3 kills in one run. Sheep: survive 3 min. |
| Abyss | Eel (default), Sea-Snake, Anglerfish, Jellyfish | Sea-Snake: reach 100 length. Anglerfish: 5 kills. Jellyfish: eat 200 food. |

Unlocks persist via JSON save file.

## 10. Audio Design

| Event | Meadow | Abyss |
|---|---|---|
| BGM | Light acoustic guitar loop | Deep ambient drone + whale calls |
| Eat | Crunchy bite | Soft bubble pop |
| Boost | Whoosh | Sonar ping |
| Death | Chicken squawk / cow moo | Submarine creak |
| Kill | Triumphant jingle | Echo pulse |
