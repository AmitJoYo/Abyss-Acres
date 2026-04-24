## NetManager — Autoload. Owns the MultiplayerPeer and connection lifecycle.
## Slice 1: hosts/joins a session. Game sync comes in slice 2.
extends Node

signal hosting_started(port: int)
signal join_succeeded
signal join_failed(reason: String)
signal player_connected(peer_id: int, nickname: String)
signal player_disconnected(peer_id: int)
signal session_closed

const DEFAULT_PORT := 8910
const MAX_PLAYERS := 20

## Lobby state — visible to clients via RPC during slice 1 plumbing.
var local_nickname: String = "Player"
var session_active: bool = false
var is_server: bool = false
## peer_id -> nickname
var players: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## ---------- Public API ----------
func host(port: int = DEFAULT_PORT) -> bool:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_warning("NetManager: create_server failed: %s" % err)
		return false
	multiplayer.multiplayer_peer = peer
	is_server = true
	session_active = true
	players.clear()
	players[1] = local_nickname  # the server itself
	hosting_started.emit(port)
	return true

func join(ip: String, port: int = DEFAULT_PORT) -> bool:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_warning("NetManager: create_client failed: %s" % err)
		join_failed.emit("Could not start client")
		return false
	multiplayer.multiplayer_peer = peer
	is_server = false
	session_active = true
	return true

func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	if session_active:
		session_active = false
		is_server = false
		players.clear()
		session_closed.emit()

func get_player_list() -> Array:
	# Returns [{id:int, name:String}, ...] sorted by id
	var ids: Array = players.keys()
	ids.sort()
	var out: Array = []
	for id in ids:
		out.append({"id": id, "name": String(players[id])})
	return out

## ---------- Multiplayer signal handlers ----------
func _on_peer_connected(peer_id: int) -> void:
	# Server side: ask the new client for its nickname.
	if is_server:
		# Send our roster to the new client so it sees existing players.
		for id in players.keys():
			_rpc_register_player.rpc_id(peer_id, id, players[id])

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
	player_disconnected.emit(peer_id)

func _on_connected_to_server() -> void:
	# Client side: announce ourselves to the server.
	_rpc_announce.rpc_id(1, local_nickname)
	join_succeeded.emit()

func _on_connection_failed() -> void:
	leave()
	join_failed.emit("Connection failed")

func _on_server_disconnected() -> void:
	leave()

## ---------- RPCs ----------
## Client → server: "here is my nickname"
@rpc("any_peer", "reliable", "call_local")
func _rpc_announce(nickname: String) -> void:
	if not is_server:
		return
	var sender := multiplayer.get_remote_sender_id()
	players[sender] = nickname
	# Broadcast the new player to everyone (including the new joiner).
	for id in players.keys():
		_rpc_register_player.rpc(id, players[id])

## Server → client: "this player exists"
@rpc("authority", "reliable", "call_local")
func _rpc_register_player(peer_id: int, nickname: String) -> void:
	players[peer_id] = nickname
	player_connected.emit(peer_id, nickname)
