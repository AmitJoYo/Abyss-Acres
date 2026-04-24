# 💡 Abyss & Acres — Deep Sea Lighting Technical Stack

> **⚠️ DEPRECATED:** The Abyss/deep-sea theme has been removed from scope. This document is retained for reference only and is not part of the current design.

## Target: Mid-Range Android (Snapdragon 680 / Mali-G57), 60 FPS

---

| Feature | Godot Node / Technique | Why It's Performant |
|---|---|---|
| **Head glow** | `PointLight2D` (1 per snake, texture: soft radial gradient) | Single draw call per light; Godot 4's 2D lighting is GPU-batched. 10–15 lights on screen is fine for mid-range. |
| **Body segment glow** | `CanvasItem.modulate` with HDR color + `AdditiveBlend` | No extra light nodes — just a blend mode change. Near-zero cost. |
| **Marine snow** | `GPUParticles2D` (one global emitter, ~200 particles) | GPU-driven, trivial overhead vs. CPUParticles2D. |
| **Water distortion** | Fragment shader on a full-screen `ColorRect` (sin-wave UV offset) | Single full-screen pass; runs at native resolution. Cheap on Adreno/Mali. |
| **Chromatic aberration** | Fragment shader on screen-edge `ColorRect` (3-channel UV split, masked to edges only) | Masked to ~15% of screen area, so fill-rate cost is minimal. |
| **Background gradient** | Static `TextureRect` (pre-baked PNG gradient) | Zero shader cost. |

## Performance Budget

- **GPU frame time:** ~2–3ms for the full lighting stack
- **16.6ms budget** for 60 FPS → plenty of headroom
- **Hard rule:** Never more than ~15 active `PointLight2D` nodes on screen at once (cull off-screen bot lights)

## Node Tree Example (Abyss Theme)

```
Game
├── Background (TextureRect — gradient PNG)
├── WaterDistortion (ColorRect + water_distortion.gdshader)
├── World (Node2D)
│   ├── FoodPool (GPUParticles2D-like pooled nodes)
│   ├── PlayerSnake
│   │   ├── Head (Sprite2D + PointLight2D)
│   │   └── Segments (pooled Sprite2D, AdditiveBlend modulate)
│   └── BotSnakes...
├── MarineSnow (GPUParticles2D — global, camera-following)
├── ChromaticAberration (ColorRect + chromatic_aberration.gdshader, edges only)
└── HUD (CanvasLayer)
```

## Key Settings

- `PointLight2D.texture`: 64×64 radial gradient (keep small)
- `PointLight2D.energy`: 1.5–2.0 for visible glow without blowout
- `PointLight2D.texture_scale`: 3.0–5.0 depending on snake size
- `GPUParticles2D.amount`: 150–200 (marine snow)
- `GPUParticles2D.lifetime`: 8–12s (slow drift)
- All `CanvasItem` nodes on segments: `light_mask = 0` (they don't receive light, they just glow via modulate)
