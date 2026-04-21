## SaveManager — JSON-based local persistence for scores and unlocks.
extends Node

const SAVE_PATH := "user://save_data.json"

var _default_data := {
	"high_score": 0,
	"unlocked_skins": ["cow", "eel"],
	"selected_theme": "meadow",
	"selected_skin": "cow",
}

var data: Dictionary = {}

func _ready() -> void:
	data = load_data()

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return _default_data.duplicate(true)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("Corrupt save file, using defaults.")
		return _default_data.duplicate(true)
	return json.data if json.data is Dictionary else _default_data.duplicate(true)

func update_high_score(score: int) -> void:
	if score > data.get("high_score", 0):
		data["high_score"] = score
		save_data()

func unlock_skin(skin_name: String) -> void:
	var skins: Array = data.get("unlocked_skins", [])
	if skin_name not in skins:
		skins.append(skin_name)
		data["unlocked_skins"] = skins
		save_data()

func is_skin_unlocked(skin_name: String) -> bool:
	return skin_name in data.get("unlocked_skins", [])
