## GdUnit4 tests for ThemeManager (theme_manager.gd)
extends GdUnitTestSuite

## Note: These tests work with the autoload ThemeManager.
## In CI, ThemeManager must be loaded or mocked.

func test_load_meadow_theme() -> void:
	ThemeManager.set_theme("meadow")
	assert_str(ThemeManager.current_theme_name).is_equal("meadow")

func test_invalid_theme_handled() -> void:
	ThemeManager.set_theme("meadow")  # set known state
	ThemeManager.set_theme("invalid_name")
	# Should remain unchanged
	assert_str(ThemeManager.current_theme_name).is_equal("meadow")
