## Minimap — Small overview showing player, bots, and food on the torus world.
## Place inside the HUD CanvasLayer.
class_name Minimap
extends Control

@export var map_size: float = 150.0        # UI pixel size of the minimap square
@export var player_dot_color: Color = Color(0.2, 1.0, 0.4)
@export var bot_dot_color: Color = Color(1.0, 0.3, 0.3)
@export var food_dot_color: Color = Color(1.0, 1.0, 0.4, 0.5)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.3)
@export var bg_color: Color = Color(0.0, 0.0, 0.0, 0.4)

var player_pos: Vector2 = Vector2.ZERO
var bot_positions: Array[Vector2] = []
var food_positions: Array[Vector2] = []

func _ready() -> void:
	custom_minimum_size = Vector2(map_size, map_size)
	size = Vector2(map_size, map_size)

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size, map_size)), bg_color)

	# Food dots
	for pos in food_positions:
		var uv := _world_to_minimap(pos)
		draw_circle(uv, 1.5, food_dot_color)

	# Bot dots
	for pos in bot_positions:
		var uv := _world_to_minimap(pos)
		draw_circle(uv, 3.0, bot_dot_color)

	# Player dot
	var player_uv := _world_to_minimap(player_pos)
	draw_circle(player_uv, 4.0, player_dot_color)

	# Border
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size, map_size)), border_color, false, 1.0)

func update_positions(p_player: Vector2, p_bots: Array[Vector2], p_food: Array[Vector2]) -> void:
	player_pos = p_player
	bot_positions = p_bots
	food_positions = p_food
	queue_redraw()

## Map world coords [-HALF, +HALF] → minimap [0, map_size].
func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var hw := WorldWrap.HALF_WORLD
	return Vector2(
		(world_pos.x + hw) / WorldWrap.WORLD_SIZE * map_size,
		(world_pos.y + hw) / WorldWrap.WORLD_SIZE * map_size,
	)
