# 🎨 Abyss & Acres — UI & Art Prompts for AI Image Generation

> Use these prompts with Midjourney, DALL-E, Stable Diffusion, or similar tools.
> All assets target **2D top-down** perspective, **transparent PNG**, **512×512** unless noted.

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
Set of 4 tiny cartoon crop icons arranged in a row: red apple, yellow corn cob, orange carrot, green cabbage. Top-down, mobile game style, vibrant colors, transparent background, each 64x64
```

### Background — Grass Tile
```
Seamless tileable top-down grass texture, lush green, cartoon style, slight variation in shade, suitable for mobile game, 512x512, no shadows
```

### Particles — Pollen & Butterflies
```
Sprite sheet of tiny floating pollen dots and small colorful butterflies, top-down, cartoon style, transparent background, soft glow, 256x256 sheet with 4x4 grid
```

### Death VFX — Feather Poof
```
Sprite sheet of cartoon feathers exploding outward in a poof, 4 frames, white and brown feathers, motion blur, transparent background, 256x256 per frame
```

---

## 🌊 Theme B: The Abyss

### Snake Heads (top-down, centered, transparent bg)

**Eel**
```
Top-down view of a bioluminescent eel head, deep sea style, dark body with glowing cyan/teal stripes, menacing small eyes with glow, sleek elongated shape, flat 2D sprite, transparent background, 512x512
```

**Sea-Snake**
```
Top-down view of a bioluminescent sea snake head, banded pattern with glowing blue and purple rings, forked tongue, deep ocean style, flat 2D sprite, transparent background, 512x512
```

**Anglerfish**
```
Top-down view of a cartoon anglerfish head, large mouth with sharp teeth, glowing lure dangling from forehead emitting yellow light, dark textured skin, deep sea style, flat 2D sprite, transparent background, 512x512
```

**Jellyfish**
```
Top-down view of a translucent jellyfish cap, glowing pink and purple bioluminescence, soft bell shape, ethereal glow effect, deep sea style, flat 2D sprite, transparent background, 512x512
```

### Snake Body Segment
```
Small round circle sprite, dark navy with subtle bioluminescent cyan edge glow, translucent center, deep sea style, transparent background, 64x64
```

### Food — Plankton & Shrimp
```
Set of tiny glowing deep sea food icons: 2 plankton clusters (cyan glow), 1 small shrimp (pink glow), 1 krill (green glow). Top-down, bioluminescent style, transparent background, each 64x64
```

### Background — Deep Sea Gradient
```
Vertical gradient background, deep navy blue at top transitioning to near-black at bottom, subtle caustic light patterns, no objects, atmospheric deep ocean feel, 1920x1080
```

### Particles — Marine Snow
```
Sprite sheet of tiny white and pale blue dots of varying sizes, some slightly elongated, simulating marine snow particles, transparent background, 128x128 sheet with 4x4 grid
```

### Death VFX — Ink Cloud
```
Sprite sheet of dark ink cloud expanding and fading, 6 frames, starts as dense black blob then disperses into translucent wisps, deep sea style, transparent background, 256x256 per frame
```

---

## 📱 UI Elements

### Main Menu Background
```
Split-screen illustration: left half is a sunny cartoon farm meadow with rolling green hills, right half is a dark deep ocean abyss with bioluminescent glow. Smooth gradient transition in the middle. Mobile game title screen style, 1920x1080
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
