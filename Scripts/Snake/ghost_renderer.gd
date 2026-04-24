## GhostRenderer — Draws duplicate sprites at world edges for seamless wrapping.
## Attach as a child of any snake (head or managed by BodyManager).
## Call update_ghosts() each frame with the list of visible segment positions.
class_name GhostRenderer
extends Node2D

## How close to the edge before we spawn ghosts (slightly larger than half-viewport).
@export var edge_margin: float = 600.0

## Pool of ghost sprites — reused each frame.
var _ghost_sprites: Array[Sprite2D] = []
var _ghost_index: int = 0
var _segment_texture: Texture2D = null
var _head_texture: Texture2D = null
var _segment_scale: Vector2 = Vector2.ONE
var _head_scale: Vector2 = Vector2.ONE

func setup(segment_texture: Texture2D, head_texture: Texture2D = null, segment_display_size: float = 18.0, head_display_size: float = 40.0) -> void:
	_segment_texture = segment_texture
	_head_texture = head_texture
	if segment_texture:
		var s := segment_display_size / float(segment_texture.get_width())
		_segment_scale = Vector2(s, s)
	if head_texture:
		var s := head_display_size / float(head_texture.get_width())
		_head_scale = Vector2(s, s)

## Call once per frame. Provide head pos + all segment positions.
func update_ghosts(head_pos: Vector2, segment_positions: Array[Vector2], head_rotation: float = 0.0) -> void:
	_ghost_index = 0

	# Ghost for head
	_draw_ghosts_for(head_pos, head_rotation, true)

	# Ghosts for body segments near world edges only (skip interior segments)
	var edge_threshold := WorldWrap.HALF_WORLD - edge_margin
	for i in segment_positions.size():
		var pos := segment_positions[i]
		if absf(pos.x) > edge_threshold or absf(pos.y) > edge_threshold:
			_draw_ghosts_for(pos, 0.0, false)

	# Hide unused ghost sprites
	for j in range(_ghost_index, _ghost_sprites.size()):
		_ghost_sprites[j].visible = false

func _draw_ghosts_for(pos: Vector2, rot: float, is_head: bool) -> void:
	var ghosts := WorldWrap.get_ghost_positions(pos, edge_margin)
	for ghost_pos in ghosts:
		var spr := _acquire_ghost_sprite()
		spr.position = ghost_pos
		spr.rotation = rot
		spr.texture = _head_texture if (is_head and _head_texture) else _segment_texture
		spr.scale = _head_scale if (is_head and _head_texture) else _segment_scale
		spr.visible = true
		spr.modulate.a = 0.85

func _acquire_ghost_sprite() -> Sprite2D:
	if _ghost_index < _ghost_sprites.size():
		var spr := _ghost_sprites[_ghost_index]
		_ghost_index += 1
		return spr
	# Create new
	var spr := Sprite2D.new()
	spr.z_index = -1
	add_child(spr)
	_ghost_sprites.append(spr)
	_ghost_index += 1
	return spr

## Cleanup.
func clear_ghosts() -> void:
	for spr in _ghost_sprites:
		spr.visible = false
	_ghost_index = 0
