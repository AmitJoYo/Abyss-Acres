## ObjectPool — Generic reusable-node pool to avoid allocation spikes.
class_name ObjectPool
extends Node

var _scene: PackedScene
var _pool: Array[Node] = []
var _active: Array[Node] = []

func _init(scene: PackedScene, initial_count: int = 20) -> void:
	_scene = scene
	for i in initial_count:
		_create_instance()

func _create_instance() -> Node:
	var inst := _scene.instantiate()
	inst.process_mode = Node.PROCESS_MODE_DISABLED
	inst.visible = false
	add_child(inst)
	_pool.append(inst)
	return inst

## Get a node from the pool (or create one if exhausted).
func acquire() -> Node:
	var inst: Node
	if _pool.size() > 0:
		inst = _pool.pop_back()
	else:
		inst = _create_instance()
		_pool.erase(inst)  # was auto-added, remove from pool

	inst.process_mode = Node.PROCESS_MODE_INHERIT
	inst.visible = true
	_active.append(inst)
	return inst

## Return a node to the pool.
func release(inst: Node) -> void:
	if inst in _active:
		_active.erase(inst)
	if inst not in _pool:
		inst.process_mode = Node.PROCESS_MODE_DISABLED
		inst.visible = false
		inst.position = Vector2(-9999, -9999)
		_pool.append(inst)

## Release all active nodes back to pool.
func release_all() -> void:
	for inst in _active.duplicate():
		release(inst)

## How many are currently in use.
func active_count() -> int:
	return _active.size()

## How many are available without allocation.
func available_count() -> int:
	return _pool.size()
