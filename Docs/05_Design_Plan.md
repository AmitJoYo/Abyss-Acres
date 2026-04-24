# 🎮 Abyss & Acres — Game Design Plan

Reflects the shipped offline build (Sprints 1–8). Multiplayer specifics live
in [08_Online_Plan.md](08_Online_Plan.md).

## 1. Game Loop

```
Main Menu → pick Skin + Mode → Game.tscn → Eat / Grow / Avoid / Kill
         ↓                                              ↓
       Multiplayer ──→ Lobby ──→ Host or Join         Die → Score → Retry / Menu
```

### Per-physics-tick loop (`game.gd::_physics_process`)
1. Recenter the world on the player when drift > 100 px (player stays at origin).
2. Update camera follow + zoom.
3. Every 3rd frame: feed AI data (head positions, lengths, food positions).
4. Food collisions (spatial hash, eaten food removed — **no respawn on eat**).
5. Every 2nd frame: death collisions (head ↔ other bodies, head-to-head, self).
6. Magnet pull on the player.
7. Power-up pickup checks.
8. Power-up spawn timer.
9. **Food lifetime tick** — pellets fade and despawn after 12 s.
10. Ghost renderer for edge wrap.
11. Every 5th frame: minimap update.
12. Bot respawn queue.
13. Screen shake.
14. Mode tick (timed / shrinking / last-standing).
15. Every 120th frame: bot difficulty rescale.
16. Crown indicator + king arrow.

## 2. Player Snake

| Attribute | Value |
|---|---|
| Base speed | 200 px/s |
| Boost mult | 1.6× |
| Boost cost | 1 segment / 0.6 s while boosting |
| Turn rate | smoothed (lerp on heading) |
| Segment spacing | 8 px in history buffer |
| Starting segments | 5 |
| **Max segments** | **180** (mobile cap, was 500) |
| Spawn invulnerability | 1.25 s with cyan shield ring |
| Self-collision | only past segment 120, with 80% skip + ¼-radius |

## 3. Growth & Scoring

| Source | Segments | Score |
|---|---|---|
| Food pellet | +1 | +10 |
| Score×2 powerup | — | doubles all gains for 10 s |
| Kill another snake | — | +100 |
| Killing the last bot in Last Standing | — | +1000 |

`SaveManager.data["high_score"]` persists the all-time best.

## 4. Power-ups

| Kind | Effect | Duration |
|---|---|---|
| **SPEED** | 1.5× movement | 5 s |
| **SHIELD** | Invulnerable to body collisions | 5 s |
| **MAGNET** | Pulls food within 220 px toward head at 320 px/s | 8 s |
| **SCORE_X2** | Doubles food score | 10 s |

- Spawn cadence: every 12–22 s, max 5 on map at once
- Spawn anchored 280–700 px from player, never on top
- HUD panel shows live timer per active power-up

## 5. AI Bot Behavior

State machine: **Wander / Chase / Avoid / Hunt** (in `ai_brain.gd`).

### Personalities
Each spawned bot picks one personality at random and gets unique stat tweaks:

| Personality | Behavior |
|---|---|
| BALANCED | Default mix of food + threat awareness |
| AGGRESSIVE | Low fear, high hunt range, chases other heads |
| COWARDLY | High fear, big threat radius, avoids fights |
| HUNTER | Huge hunt range, prefers heads over food |
| GLUTTON | Massive food range, ignores threats |

### Spawning
- Initial: ~5 bots
- Cap scales with difficulty (currently up to ~12)
- Bots respawn after `BOT_RESPAWN_DELAY` (3 s) unless mode = Last Standing

## 6. Death & Food Economy

1. Head collides with any body segment, world border, or mode boundary.
2. Death VFX (feather poof) + screen shake (player only).
3. Body dissolves into food: **every 2nd segment** drops a pellet at its
   former position.
4. Each pellet lives **12 s**, fades the last **1.5 s**, then despawns.
5. Hard cap of **250** food pellets on the map at any time.
6. Initial seed: **60** pellets at game start. **No respawn on eat** — food
   only enters the world via deaths.

This keeps the per-frame food spatial-hash bounded so framerate doesn't degrade
in long matches.

## 7. World Layout

- **Size**: 4000 × 4000 px (torus)
- **Recenter**: when player drifts > 100 px from origin, the entire world
  (snakes, food, power-ups, grid, arena center) shifts by `-offset` and is
  re-wrapped. Grid uses `fposmod` so the tile pattern stays seamless.
- **Viewport**: 1080×1920 portrait (mobile renderer)

## 8. Game Modes

| Mode | Win / End condition |
|---|---|
| **Classic** | Endless survival, die to game-over screen |
| **Timed 3min** | Player auto-dies at 3:00, highest score wins |
| **Shrinking** | Arena radius shrinks 1900 → 350 over 240 s; outside the ring = die |
| **Last Standing** | Bots never respawn; +1000 bonus when last bot dies |

Selected via mode-row buttons on the main menu, persisted to
`SaveManager.data["selected_mode"]`. Live mode info shown in the HUD label.

## 9. Camera

- Position: smooth follow on player head
- Zoom: `lerp(1.0, 0.7, segment_count / 300.0)`, eased
- Screen shake on player death (intensity 8 px, 0.3 s)

## 10. Skin System

| Skin | Unlock |
|---|---|
| Cow | default |
| Pig | reach 50 length |
| Chicken | 3 kills in one run |
| Sheep | survive 3 min |

Per-skin segment tints in `_SKIN_SEGMENT_COLORS`. Unlocks persist via
`SaveManager.data["unlocked_skins"]`.

## 11. Audio

| Event | Source |
|---|---|
| BGM | Threaded MP3 load with procedural pad fallback (no first-frame stall) |
| Eat / Boost / Death | Procedurally generated tones at runtime |
| Volume | Music at `-18 dB`, SFX nominal |

## 12. Android-specific

- Mobile renderer, portrait 1080×1920
- Back button / system back gesture → return to main menu (handled in
  `game.gd::_notification` and `lobby.gd`)
- Network permissions in `export_presets.cfg`: INTERNET, ACCESS_NETWORK_STATE,
  ACCESS_WIFI_STATE, CHANGE_WIFI_MULTICAST_STATE

## 13. Save Data Schema (`user://save_data.json`)

```json
{
  "high_score": 0,
  "unlocked_skins": [0],
  "selected_skin": 0,
  "selected_mode": 0,
  "selected_theme": "Meadow",
  "nickname": "Player"
}
```
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
| Small (Apple) | +1 | +10 |
| Medium (Corn) | +2 | +25 |
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
- Death VFX plays (feather poof)
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

| Skin (Head) | Unlock Condition |
|---|---|
| Cow (default) | — |
| Pig | Reach 50 length |
| Chicken | 3 kills in one run |
| Sheep | Survive 3 min |

Unlocks persist via JSON save file.

## 10. Audio Design

| Event | Sound |
|---|---|
| BGM | Light acoustic guitar loop |
| Eat | Crunchy bite |
| Boost | Whoosh |
| Death | Chicken squawk / cow moo |
| Kill | Triumphant jingle |
