## Powerup — Lightweight pickup with a colored sprite + glow.
## Drop in the world via PowerupManager; eaten by snakes like food.
class_name Powerup
extends Node2D

enum Kind { SPEED, SHIELD, MAGNET, SCORE_X2 }

const COLORS := {
	Kind.SPEED: Color(1.0, 0.9, 0.2),     # yellow
	Kind.SHIELD: Color(0.4, 0.85, 1.0),   # cyan
	Kind.MAGNET: Color(0.8, 0.4, 1.0),    # purple
	Kind.SCORE_X2: Color(1.0, 0.65, 0.0), # orange-gold
}

const ICONS := {
	Kind.SPEED: "⚡",
	Kind.SHIELD: "🛡",
	Kind.MAGNET: "🧲",
	Kind.SCORE_X2: "★",
}

const SIZE := 44.0
const PULSE_SPEED := 4.0

var kind: int = Kind.SPEED
var _pulse_t: float = 0.0
var _sprite: Sprite2D = null

func _ready() -> void:
	z_index = 3
	_sprite = Sprite2D.new()
	_sprite.texture = _make_disc_texture(int(SIZE), COLORS[kind])
	_sprite.scale = Vector2.ONE
	add_child(_sprite)

	var label := Label.new()
	label.text = ICONS[kind]
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(SIZE, SIZE)
	label.position = Vector2(-SIZE * 0.5, -SIZE * 0.5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _process(delta: float) -> void:
	_pulse_t += delta * PULSE_SPEED
	var s := 1.0 + sin(_pulse_t) * 0.12
	if _sprite:
		_sprite.scale = Vector2(s, s)

static func _make_disc_texture(diameter: int, color: Color) -> ImageTexture:
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var r := diameter * 0.5
	var center := Vector2(r, r)
	for x in diameter:
		for y in diameter:
			var d: float = Vector2(x, y).distance_to(center)
			if d <= r:
				var t: float = d / r
				var a: float = 1.0 - smoothstep(0.7, 1.0, t)
				var rgb: Color = color.lerp(Color.WHITE, 1.0 - t * 0.6)
				img.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, a))
	return ImageTexture.create_from_image(img)
