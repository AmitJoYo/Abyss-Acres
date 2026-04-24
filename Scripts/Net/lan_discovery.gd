## LanDiscovery — UDP broadcast for finding hosts on the local network.
## Hosts broadcast a small JSON beacon every BEACON_INTERVAL seconds.
## Clients listen on the same port and surface discovered games.
extends Node

signal host_found(info: Dictionary)  # {name, ip, port, last_seen}

const BEACON_PORT := 8911
const BEACON_INTERVAL := 1.0
const HOST_TIMEOUT := 4.0  # drop hosts not heard from in this many seconds
const MAGIC := "abyss-acres-v1"

var _broadcast_socket: PacketPeerUDP = null
var _listen_socket: PacketPeerUDP = null
var _broadcasting: bool = false
var _listening: bool = false
var _broadcast_payload: PackedByteArray = PackedByteArray()
var _broadcast_timer: float = 0.0

## key = "ip:port" → {name, ip, port, last_seen}
var hosts: Dictionary = {}

func _process(delta: float) -> void:
	if _broadcasting:
		_broadcast_timer -= delta
		if _broadcast_timer <= 0.0:
			_broadcast_timer = BEACON_INTERVAL
			_send_beacon()

	if _listening and _listen_socket:
		while _listen_socket.get_available_packet_count() > 0:
			var pkt := _listen_socket.get_packet()
			var sender_ip := _listen_socket.get_packet_ip()
			_handle_packet(pkt, sender_ip)
		_prune_stale_hosts()

## ---------- Hosting beacon ----------
func start_broadcasting(name: String, game_port: int) -> void:
	stop_broadcasting()
	_broadcast_socket = PacketPeerUDP.new()
	_broadcast_socket.set_broadcast_enabled(true)
	# Bind to ephemeral port so the OS picks one
	var err := _broadcast_socket.bind(0)
	if err != OK:
		push_warning("LanDiscovery: bind failed (%s)" % err)
		return
	_broadcast_socket.set_dest_address("255.255.255.255", BEACON_PORT)
	var payload := {
		"magic": MAGIC,
		"name": name,
		"port": game_port,
	}
	_broadcast_payload = JSON.stringify(payload).to_utf8_buffer()
	_broadcasting = true
	_broadcast_timer = 0.0  # send immediately

func stop_broadcasting() -> void:
	_broadcasting = false
	if _broadcast_socket:
		_broadcast_socket.close()
		_broadcast_socket = null

func _send_beacon() -> void:
	if _broadcast_socket and _broadcast_payload.size() > 0:
		_broadcast_socket.put_packet(_broadcast_payload)

## ---------- Listening for hosts ----------
func start_listening() -> void:
	stop_listening()
	_listen_socket = PacketPeerUDP.new()
	var err := _listen_socket.bind(BEACON_PORT)
	if err != OK:
		push_warning("LanDiscovery: listen bind failed (%s)" % err)
		_listen_socket = null
		return
	_listening = true
	hosts.clear()

func stop_listening() -> void:
	_listening = false
	hosts.clear()
	if _listen_socket:
		_listen_socket.close()
		_listen_socket = null

func _handle_packet(pkt: PackedByteArray, sender_ip: String) -> void:
	var text := pkt.get_string_from_utf8()
	if text.is_empty():
		return
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var d = json.data
	if not (d is Dictionary) or d.get("magic") != MAGIC:
		return
	var info := {
		"name": String(d.get("name", "Unknown")),
		"ip": sender_ip,
		"port": int(d.get("port", 0)),
		"last_seen": Time.get_ticks_msec(),
	}
	var key := "%s:%d" % [info["ip"], info["port"]]
	var existed := hosts.has(key)
	hosts[key] = info
	if not existed:
		host_found.emit(info)

func _prune_stale_hosts() -> void:
	var now := Time.get_ticks_msec()
	var cutoff := int(HOST_TIMEOUT * 1000.0)
	var to_drop: Array = []
	for k in hosts.keys():
		if now - int(hosts[k]["last_seen"]) > cutoff:
			to_drop.append(k)
	for k in to_drop:
		hosts.erase(k)

func get_hosts() -> Array:
	# Returns the values of the hosts dictionary as an array.
	return hosts.values()
