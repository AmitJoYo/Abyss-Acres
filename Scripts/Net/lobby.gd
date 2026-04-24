## Lobby — Multiplayer entry screen.
## Lets the player set a nickname, host a session, see discovered LAN games,
## or join by manual IP. Slice 1: just plumbing — clicking "Host" or "Join"
## drops into the existing single-player Game scene for now (offline parity).
## Slice 2 will wire actual networked snakes.
extends Control

const LanDiscoveryScript := preload("res://Scripts/Net/lan_discovery.gd")

@onready var _nickname_field: LineEdit = $Panel/VBox/Row1/NicknameField
@onready var _ip_field: LineEdit = $Panel/VBox/Row3/IpField
@onready var _host_button: Button = $Panel/VBox/Row2/HostButton
@onready var _join_ip_button: Button = $Panel/VBox/Row3/JoinButton
@onready var _back_button: Button = $Panel/VBox/Row4/BackButton
@onready var _hosts_list: VBoxContainer = $Panel/VBox/HostsScroll/HostsList
@onready var _hosts_label: Label = $Panel/VBox/HostsLabel
@onready var _status_label: Label = $Panel/VBox/StatusLabel

var _discovery: Node = null

func _ready() -> void:
	_nickname_field.text = SaveManager.data.get("nickname", "Player")
	_nickname_field.text_changed.connect(_on_nickname_changed)
	_host_button.pressed.connect(_on_host_pressed)
	_join_ip_button.pressed.connect(_on_join_ip_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	_discovery = LanDiscoveryScript.new()
	_discovery.name = "LanDiscovery"
	add_child(_discovery)
	_discovery.host_found.connect(_on_host_found)
	_discovery.start_listening()

	_status_label.text = "Searching for games on your network…"

func _process(_delta: float) -> void:
	# Refresh the discovered-hosts list every frame (cheap) so stale entries
	# disappear quickly.
	_refresh_hosts_ui()

func _exit_tree() -> void:
	if _discovery:
		_discovery.stop_listening()

## ---------- UI events ----------
func _on_nickname_changed(text: String) -> void:
	NetManager.local_nickname = text.strip_edges()
	SaveManager.data["nickname"] = NetManager.local_nickname
	SaveManager.save_data()

func _on_host_pressed() -> void:
	_save_nickname()
	if NetManager.host():
		_status_label.text = "Hosting on port %d…" % NetManager.DEFAULT_PORT
		_discovery.start_broadcasting(NetManager.local_nickname + "'s game", NetManager.DEFAULT_PORT)
		# Slice 1: drop into the offline game scene. Slice 2 will spawn the
		# networked game scene with remote players.
		_enter_game_scene()
	else:
		_status_label.text = "Failed to host."

func _on_join_ip_pressed() -> void:
	_save_nickname()
	var ip := _ip_field.text.strip_edges()
	if ip.is_empty():
		_status_label.text = "Enter an IP first."
		return
	if NetManager.join(ip):
		_status_label.text = "Connecting to %s…" % ip
		# Slice 1: clients also drop into the offline scene as a placeholder.
		_enter_game_scene()
	else:
		_status_label.text = "Failed to start client."

func _on_join_discovered_pressed(info: Dictionary) -> void:
	_save_nickname()
	if NetManager.join(info["ip"], info["port"]):
		_status_label.text = "Connecting to %s (%s)…" % [info["name"], info["ip"]]
		_enter_game_scene()
	else:
		_status_label.text = "Failed to start client."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_host_found(_info: Dictionary) -> void:
	# UI refreshes from _process, no work needed here.
	pass

## ---------- Helpers ----------
func _save_nickname() -> void:
	NetManager.local_nickname = _nickname_field.text.strip_edges()
	if NetManager.local_nickname.is_empty():
		NetManager.local_nickname = "Player"
	SaveManager.data["nickname"] = NetManager.local_nickname
	SaveManager.save_data()

func _enter_game_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _refresh_hosts_ui() -> void:
	if not _discovery:
		return
	var found: Array = _discovery.get_hosts()
	if found.is_empty():
		_hosts_label.text = "Discovered Games (none yet)"
	else:
		_hosts_label.text = "Discovered Games (%d):" % found.size()

	# Rebuild children — small list, so simplicity wins
	for child in _hosts_list.get_children():
		child.queue_free()
	for info in found:
		var btn := Button.new()
		btn.text = "%s   (%s)" % [info["name"], info["ip"]]
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_join_discovered_pressed.bind(info))
		_hosts_list.add_child(btn)

## ---------- Android back button ----------
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
