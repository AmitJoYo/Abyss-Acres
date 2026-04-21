## WorldBorder — Draws visual boundary lines / subtle grid for the world edges.
## Add as a child of the World node in Game.tscn.
class_name WorldBorder
extends Node2D

@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var border_width: float = 3.0

func _draw() -> void:
	var hw := WorldWrap.HALF_WORLD
	# Four edges of the world box
	var tl := Vector2(-hw, -hw)
	var tr := Vector2( hw, -hw)
	var bl := Vector2(-hw,  hw)
	var br := Vector2( hw,  hw)

	draw_line(tl, tr, border_color, border_width)
	draw_line(tr, br, border_color, border_width)
	draw_line(br, bl, border_color, border_width)
	draw_line(bl, tl, border_color, border_width)
