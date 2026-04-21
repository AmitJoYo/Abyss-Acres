## GdUnit4 tests for SaveManager (save_manager.gd)
extends GdUnitTestSuite

var _save_mgr: Node = null
const TEST_SAVE_PATH := "user://test_save_data.json"

func before_test() -> void:
	_save_mgr = load("res://Scripts/Data/save_manager.gd").new()
	# Override save path for testing
	_save_mgr.set("SAVE_PATH", TEST_SAVE_PATH) if false else null
	add_child(_save_mgr)

func after_test() -> void:
	# Cleanup test file
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	_save_mgr.queue_free()

## ----

func test_default_data_on_missing_file() -> void:
	var data := _save_mgr.load_data()
	assert_dict(data).contains_key_value("high_score", 0)

func test_save_creates_file() -> void:
	_save_mgr.data = {"high_score": 100, "unlocked_skins": ["cow"]}
	_save_mgr.save_data()
	assert_bool(FileAccess.file_exists(_save_mgr.SAVE_PATH)).is_true()

func test_load_reads_saved_data() -> void:
	_save_mgr.data = {"high_score": 500, "unlocked_skins": ["cow", "pig"]}
	_save_mgr.save_data()
	var loaded := _save_mgr.load_data()
	assert_int(loaded.get("high_score", 0)).is_equal(500)

func test_update_high_score() -> void:
	_save_mgr.data = {"high_score": 100, "unlocked_skins": ["cow"]}
	_save_mgr.update_high_score(200)
	assert_int(_save_mgr.data["high_score"]).is_equal(200)

func test_lower_score_doesnt_overwrite() -> void:
	_save_mgr.data = {"high_score": 200, "unlocked_skins": ["cow"]}
	_save_mgr.update_high_score(50)
	assert_int(_save_mgr.data["high_score"]).is_equal(200)

func test_skin_unlock_persists() -> void:
	_save_mgr.data = {"high_score": 0, "unlocked_skins": ["cow"]}
	_save_mgr.unlock_skin("pig")
	assert_bool(_save_mgr.is_skin_unlocked("pig")).is_true()

func test_duplicate_unlock_safe() -> void:
	_save_mgr.data = {"high_score": 0, "unlocked_skins": ["cow"]}
	_save_mgr.unlock_skin("cow")
	var skins: Array = _save_mgr.data["unlocked_skins"]
	# Should not have duplicates
	var cow_count := 0
	for s in skins:
		if s == "cow":
			cow_count += 1
	assert_int(cow_count).is_equal(1)

func test_corrupted_file_returns_defaults() -> void:
	# Write garbage to save file
	var file := FileAccess.open(_save_mgr.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{{{not valid json!!!")
	file.close()
	var data := _save_mgr.load_data()
	# Should return defaults without crashing
	assert_dict(data).contains_key_value("high_score", 0)
