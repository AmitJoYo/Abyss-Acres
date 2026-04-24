# 🐍 Abyss & Acres — Project Roadmap

## Engine: Godot 4.6.2 (GDScript), mobile renderer, Android target.

Status legend: ✅ shipped · 🔧 partial · ⏳ planned

---

## Sprint 1 — Core Snake & Player Physics ✅
- ✅ Position-history ring buffer for smooth, non-grid body following
- ✅ Head movement driven by virtual joystick input
- ✅ Body segment spawning via `ObjectPool`
- ✅ Boost mechanic (speed mult + segment cost)
- ✅ Camera follow with growth-driven zoom-out

## Sprint 2 — Torus World Wrap ✅
- ✅ 4000×4000 torus, player-at-origin recenter (>100 px drift)
- ✅ Wrap-aware distance & delta helpers in `WorldWrap`
- ✅ Ghost-rendering near edges (`GhostRenderer`)
- ✅ Food spawned in wrapped coordinates
- ✅ Minimap with wrapped positions

## Sprint 3 — Theme & Art Pipeline ✅
- ✅ `ThemeManager` + `ThemeData` resource
- ✅ Meadow theme: grass tile, animal heads (cow/pig/chicken/sheep), crops
- ✅ Background grass-wind shader
- ✅ Ambient butterflies / particles
- ✅ Death VFX (feather poof)

## Sprint 4 — AI Bots & Gameplay Loop ✅
- ✅ `AIBrain` state machine (Wander / Chase / Avoid / Hunt)
- ✅ Head-to-body collisions (spatial hash, torus-aware, sampled stride for perf)
- ✅ Bots dissolve into food on death; player-killed snake = +100 bonus
- ✅ Difficulty scaling (bot count + speed over time)
- ✅ **Five AI personalities**: BALANCED, AGGRESSIVE, COWARDLY, HUNTER, GLUTTON

## Sprint 5 — Polish, UI & Android Export ✅
- ✅ Virtual joystick + boost button HUD
- ✅ Main menu, skin select row, mode select row
- ✅ Local high-score & skin-unlock persistence (`SaveManager`, JSON)
- ✅ Android export pipeline (`export_presets.cfg`, debug keystore)
- ✅ Touch input tuned, APK deploys to phone
- ✅ Android **back button** returns to main menu (not app exit)

## Sprint 6 — Power-ups & Game Modes ✅
- ✅ Four power-ups: SPEED, SHIELD, MAGNET, SCORE_X2
- ✅ HUD power-up panel with live timers
- ✅ Spawn invulnerability (1.25 s cyan ring)
- ✅ Game modes: **Classic**, **Timed 3min**, **Shrinking arena**, **Last Standing**
- ✅ Mode selector on main menu, mode HUD label in-game

## Sprint 7 — Audio ✅
- ✅ Threaded MP3 music load with procedural pad fallback (no first-frame stall)
- ✅ Procedural SFX (eat, boost, death) generated at runtime

## Sprint 8 — Performance Hardening ✅
- ✅ `MAX_SEGMENTS` reduced from 500 → 180 (mobile cap)
- ✅ Spatial hash insertion stride (every 3rd segment)
- ✅ Food economy: small initial seed (60), no respawn-on-eat, 12 s lifetime
  with fade, hard cap 250
- ✅ Death drops every 2nd segment (denser harvest, still bounded)
- ✅ Recenter routine bug fixed (orphaned grid-fposmod indentation)
- ✅ Power-up positions shift with world during recenter (no longer appear to
  follow the player)

## Sprint 9 — Online Multiplayer 🔧
See [08_Online_Plan.md](08_Online_Plan.md) for the full plan.
- ✅ `NetManager` autoload (ENet, host/join/leave, nickname registry)
- ✅ `LanDiscovery` UDP broadcast on port 8911 (auto-find LAN games)
- ✅ Lobby scene: nickname field, discovered games list, manual IP join, back
- ✅ Multiplayer button on main menu
- ✅ Android network permissions (INTERNET, ACCESS_*_STATE, multicast)
- ⏳ **Slice 2**: server-authoritative simulation, 15 Hz snapshots, client
  prediction, networked snake spawn per peer, server-side bots
- ⏳ Hosted production server (VPS, headless export)

## Sprint 10 — Themes B & C ⏳
- ⏳ Deep-Sea theme (see [04_Deep_Sea_Lighting_Stack.md](04_Deep_Sea_Lighting_Stack.md))
- ⏳ Third theme TBD
- ⏳ Theme-pack pipeline / cosmetic unlocks
# 🐍 Abyss & Acres — Project Roadmap

## Engine: Godot 4.x (GDScript)

---

### Sprint 1 — Core Snake & Player Physics (Days 1–3)
- Position-History Buffer for smooth, non-grid body following
- Head movement driven by virtual joystick input
- Body segment spawning via Object Pool
- "Pulse" boost mechanic (speed burst + segment gap compensation)
- Basic camera follow

### Sprint 2 — Torus World Wrap (Days 4–5)
- Boundary teleportation for head and all body segments
- Ghost-rendering at edges
- Food spawning within world bounds with wrap-aware distance checks
- Minimap with wrapped coordinates

### Sprint 3 — Theme Manager & Art Pipeline (Days 6–8)
- Theme manager system (Meadow theme)
- Background shader: grass wind-sway
- Particle systems: pollen/butterflies
- Death VFX: feather poof

### Sprint 4 — AI Bots & Gameplay Loop (Days 9–11)
- AI snake controller (wander, chase food, avoid heads)
- Head-to-body collision → death → dissolve into themed food
- Difficulty scaling (bot count, speed, aggression over time)
- Score tracking & growth curve balancing

### Sprint 5 — Polish, UI & Android Export (Days 12–14)
- Virtual joystick + boost button HUD
- Main menu, skin select, theme select screens
- Local high-score & skin-unlock persistence (JSON)
- Android performance profiling (60 FPS target, mid-range)
- Touch input tuning, APK export, final QA
