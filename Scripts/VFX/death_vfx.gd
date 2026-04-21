## DeathVFX — Plays a one-shot particle effect at death location, then frees itself.
class_name DeathVFX
extends Node2D

@export var lifetime: float = 1.5

var _timer: float = 0.0

func _ready() -> void:
	# Auto-play any GPUParticles2D children
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
			child.one_shot = true

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()

## Factory: spawn a death VFX at a position.
static func spawn(scene: PackedScene, parent: Node, pos: Vector2) -> void:
	if scene == null:
		return
	var inst := scene.instantiate() as Node2D
	if inst:
		inst.position = pos
		parent.add_child(inst)
