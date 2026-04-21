# Project: Abyss & Acres (Infinite .io Snake)
**Role:** Senior Game Developer & Technical Artist
**Engine:** Godot 4.x (GDScript) or Unity (C#) - [Choose your preference]
**Target:** Android (Mobile), Offline-First, 60 FPS Performance.

## 1. Core Vision
Build a premium, ad-free version of Snake.io featuring an infinite, wrapping world. The game scales between two high-fidelity themes: "The Meadow" (Farm) and "The Abyss" (Deep Sea).

## 2. Technical Architecture
- **Infinite World:** Implement "Torus Wrapping." When the head or a body segment crosses a boundary (e.g., +/- 2000px), it teleports to the opposite side seamlessly.
- **Body Logic:** Use a Position-History Buffer (Interpolation) for smooth, non-grid movement. Body segments must follow the head’s path exactly, handling the "world wrap" logic so segments don't snap/stretch when crossing the edge.
- **Collision:** Head-to-Body contact = Death. Dead snakes dissolve into "Food" items (Apples/Plankton) based on the current theme.
- **Performance:** Use Object Pooling for snake segments and food pellets.

## 3. Theme Specifications
### Theme A: The Meadow (Farm)
- **Background:** Tiling green grass texture with a wind-sway shader.
- **Player/Enemies:** Stylized Farm Animals (Cow/Pig/Chicken heads).
- **Food:** Crops (Corn, Apples, Carrots).
- **VFX:** Floating pollen, butterfly particles, "Poof of feathers" on death.

### Theme B: The Abyss (Deep Sea Bio)
- **Background:** Deep navy gradient with a "Water Distortion" shader and "Marine Snow" particles.
- **Player/Enemies:** Bio-luminescent creatures (Eel, Sea-Snake, Anglerfish).
- **Food:** Glowing Plankton and Shrimp.
- **VFX:** Chromatic aberration at screen edges, 2D PointLight2D on the head, "Ink cloud" on death.

## 4. Input & UI
- **Controls:** Virtual Joystick (Left), "Pulse" Boost Button (Right).
- **Offline Mode:** Local high scores and skin unlocks saved via JSON. No external SDKs.