## AmbientParticles — Camera-following particle layer (pollen or marine snow).
## Attach under the Game scene. Follows camera each frame.
class_name AmbientParticles
extends GPUParticles2D

var _camera: Camera2D = null

func setup(camera: Camera2D) -> void:
	_camera = camera
	emitting = true

func _process(_delta: float) -> void:
	if _camera:
		global_position = _camera.global_position
