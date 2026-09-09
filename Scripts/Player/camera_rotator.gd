extends Camera3D

var pitch : float = 0.0

@onready var player : CharacterBody3D = get_parent()
@onready var controller : Node = player

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion : InputEventMouseMotion = event as InputEventMouseMotion

		player.rotate_y(-motion.relative.x * controller.mouse_sensitivity)

		pitch = clampf(
			pitch - motion.relative.y * controller.mouse_sensitivity,
			deg_to_rad(controller.min_pitch),
			deg_to_rad(controller.max_pitch)
		)
		rotation.x = pitch
