## DeathVFX — Plays a one-shot particle effect at death location, then frees itself.
class_name DeathVFX
extends Node2D

@export var lifetime: float = 1.5

var _timer: float = 0.0
var _sprites: Array[Sprite2D] = []

## Feather poof textures (loaded once)
static var _feather_textures: Array[Texture2D] = []

static func _load_feather_textures() -> void:
	if _feather_textures.size() > 0:
		return
	var paths := [
		"res://png/ui/feather_poof_01.png",
		"res://png/ui/feather_poof_02.png",
	]
	for path in paths:
		var tex := load(path) as Texture2D
		if tex:
			_feather_textures.append(tex)

func _ready() -> void:
	_load_feather_textures()
	# Auto-play any GPUParticles2D children (legacy support)
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
			child.one_shot = true

	# Spawn feather poof sprites bursting outward
	if _feather_textures.size() > 0:
		for i in 8:
			var spr := Sprite2D.new()
			spr.texture = _feather_textures[i % _feather_textures.size()]
			spr.scale = Vector2(0.4, 0.4)
			spr.modulate.a = 1.0
			var angle := (float(i) / 8.0) * TAU + randf_range(-0.3, 0.3)
			spr.set_meta("burst_dir", Vector2(cos(angle), sin(angle)))
			spr.set_meta("burst_speed", randf_range(120.0, 250.0))
			spr.set_meta("spin", randf_range(-5.0, 5.0))
			add_child(spr)
			_sprites.append(spr)

func _process(delta: float) -> void:
	_timer += delta
	# Animate feather sprites
	var t := _timer / lifetime
	for spr in _sprites:
		var dir: Vector2 = spr.get_meta("burst_dir")
		var spd: float = spr.get_meta("burst_speed")
		var spin: float = spr.get_meta("spin")
		spr.position += dir * spd * delta * (1.0 - t)  # decelerate
		spr.rotation += spin * delta
		spr.modulate.a = 1.0 - t  # fade out
		spr.scale = Vector2(0.4, 0.4) * (1.0 + t * 0.5)  # expand slightly

	if _timer >= lifetime:
		queue_free()

## Factory: spawn a death VFX at a position.
static func spawn(scene: PackedScene, parent: Node, pos: Vector2) -> void:
	# Use sprite-based poof if feather textures exist, ignoring the PackedScene
	_load_feather_textures()
	if _feather_textures.size() > 0:
		var inst := DeathVFX.new()
		inst.position = pos
		parent.add_child(inst)
		return
	# Fallback to scene-based
	if scene == null:
		return
	var inst := scene.instantiate() as Node2D
	if inst:
		inst.position = pos
		parent.add_child(inst)
