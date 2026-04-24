# 🎨 Abyss & Acres — UI & Art Prompts for AI Image Generation

> Use these prompts with Midjourney, DALL-E, Stable Diffusion, or similar tools.
> All assets target **2D top-down** perspective, **transparent PNG**, **512×512** unless noted.

## PNG Size Checklist (Photoshop Export)

Use these exact canvas sizes and names when exporting final PNG assets:

| Asset | Final File Name | Canvas Size | Layout / Cell Size |
|---|---|---|---|
| Cow head | cow.png | 512×512 | Single sprite |
| Pig head | pig.png | 512×512 | Single sprite |
| Chicken head | chicken.png | 512×512 | Single sprite |
| Sheep head | sheep.png | 512×512 | Single sprite |
| Snake body segment | segment.png | 64×64 | Single sprite |
| Food apple | food_apple.png | 64×64 | Single sprite |
| Food corn | food_corn.png | 64×64 | Single sprite |
| Food carrot | food_carrot.png | 64×64 | Single sprite |
| Food cabbage | food_cabbage.png | 64×64 | Single sprite |
| Grass tile | grass_tile.png | 512×512 | Single tile |
| Pollen sprite 1 | pollen_01.png | 64×64 | Single sprite |
| Pollen sprite 2 | pollen_02.png | 64×64 | Single sprite |
| Pollen sprite 3 | pollen_03.png | 64×64 | Single sprite |
| Pollen sprite 4 | pollen_04.png | 64×64 | Single sprite |
| Butterfly sprite 1 | butterfly_01.png | 64×64 | Single sprite |
| Butterfly sprite 2 | butterfly_02.png | 64×64 | Single sprite |
| Butterfly sprite 3 | butterfly_03.png | 64×64 | Single sprite |
| Butterfly sprite 4 | butterfly_04.png | 64×64 | Single sprite |
| Feather poof frame 1 | feather_poof_01.png | 256×256 | Frame 1 |
| Feather poof frame 2 | feather_poof_02.png | 256×256 | Frame 2 |
| Feather poof frame 3 | feather_poof_03.png | 256×256 | Frame 3 |
| Feather poof frame 4 | feather_poof_04.png | 256×256 | Frame 4 |
| Main menu background | main_menu_bg.png | 1920×1080 | Single background |
| Virtual joystick | joystick.png | 256×256 | Single sprite |
| Boost button | boost_button.png | 128×128 | Single sprite |
| Score panel | score_panel.png | 300×80 | Single sprite |
| Game over screen | game_over.png | 600×400 | Single sprite |

Folder alignment:
- Meadow gameplay textures: Assets/Textures/Meadow/
- UI textures: Assets/Textures/UI/

Export notes:
- Keep alpha channel enabled (RGBA).
- Do not include checkerboard pixels in the actual image.
- Keep sprite sheets tightly packed with transparent background.

Naming notes:
- Use zero-padded frame/sprite numbers: 01, 02, 03, 04.
- Keep all names lowercase with underscores.

---

## 🌾 Theme A: The Meadow

### Snake Heads (top-down, centered, transparent bg)

**Cow**
```
Top-down view of a cute cartoon cow head, stylized for a mobile game, round face, black and white patches, big eyes, slight smile, flat 2D sprite, transparent background, 512x512
```

**Pig**
```
Top-down view of a cute cartoon pig head, stylized mobile game art, round pink face, small snout with nostrils visible, floppy ears, flat 2D sprite, transparent background, 512x512
```

**Chicken**
```
Top-down view of a cute cartoon chicken head, stylized mobile game, white feathers, red comb on top, orange beak pointing forward, flat 2D sprite, transparent background, 512x512
```

**Sheep**
```
Top-down view of a cute cartoon sheep head, fluffy white wool border, dark face, small ears, stylized mobile game art, flat 2D sprite, transparent background, 512x512
```

### Snake Body Segment
```
Small round circle sprite, earthy brown with subtle leather texture, slight 3D shading, cartoon mobile game style, seamless tileable, transparent background, 64x64
```

### Food — Crops
```
Single tiny cartoon crop icon (generate one at a time): red apple OR yellow corn cob OR orange carrot OR green cabbage. Top-down, mobile game style, vibrant colors, transparent background, 64x64
```

### Background — Grass Tile
```
Seamless tileable top-down grass texture, lush green, cartoon style, slight variation in shade, suitable for mobile game, 512x512, no shadows
```

### Particles — Pollen & Butterflies
```
Single tiny floating pollen dot or small colorful butterfly (generate one at a time), top-down, cartoon style, transparent background, soft glow, 64x64
```

### Death VFX — Feather Poof
```
Single frame of cartoon feathers exploding outward in a poof (generate one frame at a time for frame 1 to frame 4), white and brown feathers, motion blur, transparent background, 256x256
```

---

## 📱 UI Elements

### Main Menu Background
```
Sunny cartoon farm meadow with rolling green hills, scattered crops, and a clear blue sky. Cheerful mobile game title screen style, 1920x1080
```

### Virtual Joystick
```
Circular joystick base, semi-transparent dark gray with thin white border, inner thumb circle slightly lighter, minimal clean UI design, transparent background, 256x256
```

### Boost Button
```
Circular button with lightning bolt icon, glowing orange-yellow gradient, subtle pulse effect implied, clean mobile game UI, transparent background, 128x128
```

### Score Panel
```
Rounded rectangle UI panel, semi-transparent dark background with gold border, space for score text, compact mobile game HUD element, transparent background, 300x80
```

### Game Over Screen
```
Rounded UI card, semi-transparent dark overlay, large "GAME OVER" text area at top, space for score and high score below, two button slots (Retry / Menu), clean mobile game style, transparent background, 600x400
```

---

## 💡 Prompt Tips

- Add `--no text` (Midjourney) to avoid baked-in text on sprites
- Use `--style raw` for more consistent flat art
- For Stable Diffusion, add negative prompt: `3d render, realistic, photo, text, watermark, blurry`
- Generate at 2× resolution and downscale for crisp mobile sprites
- Always request **transparent background** for game sprites
