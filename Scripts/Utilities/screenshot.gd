extends Node

const SCREENSHOT_DIR := "res://doc/screenshots/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		_take_screenshot()
		get_viewport().set_input_as_handled()

func _take_screenshot() -> void:
	print("Taking screenshot...")
	await RenderingServer.frame_post_draw
	var dir_path := ProjectSettings.globalize_path(SCREENSHOT_DIR)
	DirAccess.make_dir_recursive_absolute(dir_path)
	if not DirAccess.dir_exists_absolute(dir_path):
		push_error("Screenshot dir not found: " + dir_path)
		return
	var now := Time.get_datetime_string_from_system(false, true)
	var stamp := now.replace(":", "-")
	var path := SCREENSHOT_DIR + "screenshot_%s.png" % stamp
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	if err == OK:
		print("Screenshot saved: ", path)
	else:
		push_error("Failed to save screenshot: ", err)