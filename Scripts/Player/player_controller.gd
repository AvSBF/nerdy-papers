extends CharacterBody3D

@export var move_speed : float = 5.0
@export var sprint_multiplier : float = 1.8
@export var mouse_sensitivity : float = 0.003
@export var min_pitch : float = -80.0
@export var max_pitch : float = 80.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
