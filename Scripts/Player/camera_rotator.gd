extends Camera3D

var pitch : float = 0.0

@onready var player : CharacterBody3D = get_parent()
@onready var controller : Node = player
@onready var _round : Node = get_tree().get_first_node_in_group("round_controller")
@onready var _base_position : Vector3 = position

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var motion : InputEventMouseMotion = event as InputEventMouseMotion

		var sign := -1.0 if _round.invert_look else 1.0
		var sens : float = controller.mouse_sensitivity

		player.rotate_y(sign * -motion.relative.x * sens)

		pitch = clampf(
			pitch + sign * -motion.relative.y * sens,
			deg_to_rad(controller.min_pitch),
			deg_to_rad(controller.max_pitch)
		)
		rotation.x = pitch

func _process(_delta: float) -> void:
	var shake : float = _round.camera_shake_strength
	if shake > 0.0:
		var amp := 0.008 * shake
		position = _base_position + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			0.0
		) * amp
	else:
		position = _base_position