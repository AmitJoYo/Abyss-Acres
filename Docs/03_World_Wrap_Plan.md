# 🌀 Abyss & Acres — World-Wrap Plan (Torus Math)

## Problem

When the head teleports from `x = +W` to `x = -W`, naïve segment-following stretches the body across the entire map.

## Solution: Wrapped Delta + Ghost Rendering

### 1. Wrapped Position-History Buffer

Every physics frame, the head's position is pushed onto a ring buffer. Each body segment reads from this buffer at an offset. The key is that **deltas** are stored, not absolute positions.

```
Δ_i = wrap(P_i - P_{i-1})

wrap(d) = d - W * round(d / W)
```

Where `W` is the world size (e.g., 4000). The `wrap()` function always returns the **shortest-path delta** across the torus, so a head jumping from `+1999` to `-2000` produces `Δx = +1`, not `-3999`.

Each segment's **render position** is computed by accumulating wrapped deltas from the head:

```
S_n = P_head + Σ(Δ_k for k=1..n)  (mod W)
```

This means segments never "know" a teleport happened — they just follow the shortest path.

### 2. Edge Ghost Rendering

When any segment is within one screen-width of a boundary, a **ghost duplicate** is drawn at `position ± W` on the relevant axis. This makes the snake appear to smoothly slide across the edge. The ghost is purely visual (no collider).

### 3. Collision via Wrapped Distance

All distance checks use the same wrap function:

```
d(A, B) = || wrap(A - B) ||
```

This guarantees food pickup and head-to-body collision work correctly near edges.

### Result

- Zero visual glitches
- Zero stretched segments
- O(1) per-segment cost

### GDScript Reference Implementation

```gdscript
const WORLD_SIZE := 4000.0
const HALF_WORLD := WORLD_SIZE / 2.0

static func wrap_position(pos: Vector2) -> Vector2:
    pos.x = fposmod(pos.x + HALF_WORLD, WORLD_SIZE) - HALF_WORLD
    pos.y = fposmod(pos.y + HALF_WORLD, WORLD_SIZE) - HALF_WORLD
    return pos

static func wrap_delta(delta: Vector2) -> Vector2:
    delta.x = delta.x - WORLD_SIZE * round(delta.x / WORLD_SIZE)
    delta.y = delta.y - WORLD_SIZE * round(delta.y / WORLD_SIZE)
    return delta

static func wrapped_distance(a: Vector2, b: Vector2) -> float:
    return wrap_delta(a - b).length()
```
