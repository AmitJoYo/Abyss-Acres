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
- Runtime theme switching system (Meadow ↔ Abyss)
- Background shaders: grass wind-sway & water distortion
- Particle systems: pollen/butterflies vs. marine snow
- Death VFX: feather poof vs. ink cloud
- Deep Sea lighting (PointLight2D on head, edge chromatic aberration)

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
