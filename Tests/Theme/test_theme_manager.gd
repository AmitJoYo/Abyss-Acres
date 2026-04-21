## GdUnit4 tests for ThemeManager (theme_manager.gd)
extends GdUnitTestSuite

## Note: These tests work with the autoload ThemeManager.
## In CI, ThemeManager must be loaded or mocked.

func test_load_meadow_theme() -> void:
	ThemeManager.set_theme("meadow")
	assert_str(ThemeManager.current_theme_name).is_equal("meadow")

func test_load_abyss_theme() -> void:
	ThemeManager.set_theme("abyss")
	assert_str(ThemeManager.current_theme_name).is_equal("abyss")

func test_abyss_enables_lighting() -> void:
	ThemeManager.set_theme("abyss")
	assert_bool(ThemeManager.use_lighting).is_true()

func test_meadow_disables_lighting() -> void:
	ThemeManager.set_theme("meadow")
	assert_bool(ThemeManager.use_lighting).is_false()

func test_invalid_theme_handled() -> void:
	ThemeManager.set_theme("meadow")  # set known state
	ThemeManager.set_theme("invalid_name")
	# Should remain unchanged
	assert_str(ThemeManager.current_theme_name).is_equal("meadow")

func test_is_abyss_helper() -> void:
	ThemeManager.set_theme("abyss")
	assert_bool(ThemeManager.is_abyss()).is_true()
	ThemeManager.set_theme("meadow")
	assert_bool(ThemeManager.is_abyss()).is_false()
