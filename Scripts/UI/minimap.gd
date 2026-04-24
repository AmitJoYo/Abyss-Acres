## Minimap — Radar-style circular display centered on player.
## Shows nearby bots and food relative to the player. No world edge visible.
class_name Minimap
extends Control

@export var map_size: float = 150.0        # UI pixel diameter
@export var radar_range: float = 1200.0    # world units visible on radar
@export var player_dot_color: Color = Color(0.2, 1.0, 0.4)
@export var bot_dot_color: Color = Color(1.0, 0.3, 0.3)
@export var food_dot_color: Color = Color(1.0, 1.0, 0.4, 0.4)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.35)

var player_pos: Vector2 = Vector2.ZERO
var bot_positions: Array[Vector2] = []
var food_positions: Array[Vector2] = []

func _ready() -> void:
	custom_minimum_size = Vector2(map_size, map_size)
	size = Vector2(map_size, map_size)

func _draw() -> void:
	var half := map_size / 2.0
	var center := Vector2(half, half)

	# Circular background
	draw_circle(center, half, bg_color)

	# Subtle range rings
	draw_arc(center, half * 0.33, 0, TAU, 32, Color(1, 1, 1, 0.06), 1.0)
	draw_arc(center, half * 0.66, 0, TAU, 32, Color(1, 1, 1, 0.06), 1.0)

	# Food dots (only those in radar range)
	for pos in food_positions:
		var uv := _world_to_radar(pos)
		if uv.distance_to(center) < half - 2:
			draw_circle(uv, 1.5, food_dot_color)

	# Bot dots
	for pos in bot_positions:
		var uv := _world_to_radar(pos)
		if uv.distance_to(center) < half - 2:
			draw_circle(uv, 3.0, bot_dot_color)

	# Player dot (always at center)
	draw_circle(center, 4.0, player_dot_color)

	# Outer ring
	draw_arc(center, half - 1, 0, TAU, 64, border_color, 1.5)

func update_positions(p_player: Vector2, p_bots: Array[Vector2], p_food: Array[Vector2]) -> void:
	player_pos = p_player
	bot_positions = p_bots
	food_positions = p_food
	queue_redraw()

## Map world position to radar pixel coords (player-centered, wrap-aware).
func _world_to_radar(world_pos: Vector2) -> Vector2:
	var half := map_size / 2.0
	var delta := WorldWrap.wrap_delta(world_pos - player_pos)
	var scale := half / radar_range
	return Vector2(half + delta.x * scale, half + delta.y * scale)
