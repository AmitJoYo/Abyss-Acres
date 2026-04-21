# 🧪 Abyss & Acres — Unit Test Plan

> Framework: [GdUnit4](https://github.com/MikeSchulze/gdUnit4) (GDScript test runner for Godot 4)
> Test location: `res://Tests/` mirroring `res://Scripts/`

---

## Test Structure

```
res://Tests/
├── Core/
│   ├── test_world_wrap.gd
│   ├── test_object_pool.gd
│   └── test_game_manager.gd
├── Snake/
│   ├── test_body_manager.gd
│   ├── test_snake_controller.gd
│   └── test_ai_brain.gd
├── Theme/
│   └── test_theme_manager.gd
└── Data/
    └── test_save_manager.gd
```

---

## Core/test_world_wrap.gd

### wrap_position
| # | Test Case | Input | Expected |
|---|---|---|---|
| 1 | Center stays unchanged | `Vector2(0, 0)` | `Vector2(0, 0)` |
| 2 | Positive overflow wraps | `Vector2(2500, 0)` | `Vector2(-1500, 0)` |
| 3 | Negative overflow wraps | `Vector2(-2500, 0)` | `Vector2(1500, 0)` |
| 4 | Exact boundary wraps | `Vector2(2000, 2000)` | `Vector2(-2000, -2000)` |
| 5 | Both axes overflow | `Vector2(3000, -3000)` | `Vector2(-1000, 1000)` |

### wrap_delta
| # | Test Case | Input | Expected |
|---|---|---|---|
| 6 | Small delta unchanged | `Vector2(10, -5)` | `Vector2(10, -5)` |
| 7 | Cross-boundary delta (positive) | `Vector2(3500, 0)` | `Vector2(-500, 0)` |
| 8 | Cross-boundary delta (negative) | `Vector2(-3800, 0)` | `Vector2(200, 0)` |
| 9 | Diagonal boundary cross | `Vector2(3500, -3500)` | `Vector2(-500, 500)` |

### wrapped_distance
| # | Test Case | A | B | Expected |
|---|---|---|---|---|
| 10 | Same point | `(0,0)` | `(0,0)` | `0.0` |
| 11 | Normal distance | `(100,0)` | `(0,0)` | `100.0` |
| 12 | Shorter through wrap | `(1900,0)` | `(-1900,0)` | `200.0` (not 3800) |

---

## Core/test_object_pool.gd

| # | Test Case | Description |
|---|---|---|
| 13 | Pool initializes with correct count | Create pool(10) → 10 inactive instances exist |
| 14 | Acquire returns instance | `pool.acquire()` returns non-null node |
| 15 | Acquire sets active | Acquired node is `visible` and `process_mode = INHERIT` |
| 16 | Release returns to pool | After `pool.release(node)`, node is invisible |
| 17 | Pool exhaustion creates new | Acquire more than initial count → pool grows |
| 18 | Double release is safe | Releasing same node twice doesn't crash or duplicate |

---

## Snake/test_body_manager.gd

| # | Test Case | Description |
|---|---|---|
| 19 | History buffer records positions | After 10 frames of movement, buffer has 10+ entries |
| 20 | Segment follows head path | Segment N position matches buffer entry at offset N × spacing |
| 21 | Wrap-crossing preserves continuity | Move head across boundary → segment distance to predecessor stays ≤ spacing + 1px |
| 22 | Growth adds segment | Call `grow(1)` → segment count increases by 1 |
| 23 | Boost shrink removes tail | Boosting for 0.8s → last segment removed |
| 24 | Max segment cap | Growing beyond 500 segments is rejected |

---

## Snake/test_snake_controller.gd

| # | Test Case | Description |
|---|---|---|
| 25 | Head moves in direction | Set direction right → after 1 frame, x increased |
| 26 | Turn rate is limited | Set direction 180° opposite → after 1 frame, rotation < π |
| 27 | Boost increases speed | Enable boost → speed equals BOOST_SPEED |
| 28 | Boost disabled at min length | Snake with 2 segments → boost rejected |
| 29 | Collision with own body = death | Curl head into own body → `died` signal emitted |
| 30 | Collision with other body = death | Head overlaps other snake segment → `died` signal emitted |
| 31 | Food pickup triggers growth | Head overlaps food → `ate_food` signal emitted, food deactivated |

---

## Snake/test_ai_brain.gd

| # | Test Case | Description |
|---|---|---|
| 32 | Wander produces movement | AI in wander state → direction is non-zero |
| 33 | Chase steers toward food | Place food at known position → AI direction points toward it |
| 34 | Avoid steers away from threat | Place enemy head nearby → AI direction points away |
| 35 | State transition: wander → chase | Spawn food within 300px → state changes to Chase |
| 36 | State transition: chase → avoid | Spawn threat within 150px → state changes to Avoid |

---

## Theme/test_theme_manager.gd

| # | Test Case | Description |
|---|---|---|
| 37 | Load meadow theme | `set_theme("meadow")` → current theme name is "meadow" |
| 38 | Load abyss theme | `set_theme("abyss")` → current theme name is "abyss" |
| 39 | Theme swap updates sprites | After swap, head sprite matches new theme data |
| 40 | Abyss enables lighting | Abyss theme → `use_lighting` is true |
| 41 | Meadow disables lighting | Meadow theme → `use_lighting` is false |
| 42 | Invalid theme name handled | `set_theme("invalid")` → no crash, theme unchanged |

---

## Data/test_save_manager.gd

| # | Test Case | Description |
|---|---|---|
| 43 | Save creates file | `save_data()` → file exists at expected path |
| 44 | Load reads saved data | Save score 500 → load → score is 500 |
| 45 | Default data on missing file | Delete save file → `load_data()` returns defaults |
| 46 | Corrupted file handled | Write garbage to save path → `load_data()` returns defaults, no crash |
| 47 | Skin unlock persists | Unlock "pig" → save → reload → "pig" is unlocked |
| 48 | High score updates correctly | Save score 100, then 200 → high score is 200 |
| 49 | Lower score doesn't overwrite | High score 200, new score 50 → high score stays 200 |

---

## Running Tests

```bash
# Via Godot editor
# Install GdUnit4 addon → Run from GdUnit4 panel

# Via CLI (CI/headless)
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add "res://Tests" --verbose
```

## Coverage Targets

| Area | Target |
|---|---|
| World wrap math | 100% |
| Object pool | 100% |
| Body manager | 90%+ |
| Snake controller | 85%+ |
| AI brain | 80%+ |
| Save/Load | 100% |
| Theme manager | 90%+ |
