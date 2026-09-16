extends Node3D

@onready var moving_part : MeshInstance3D = $"Moving Part"
@onready var creator : Node3D = get_parent().get_node("Paper Creator")

@export var initial_position : float = 0.154
@export var minimum_position : float = 0.084
@export var wait_time : float = 0.3

var _is_pressed : bool = false

func interact():
	if _is_pressed:
		return
	_is_pressed = true

	moving_part.position.y = minimum_position
	creator.spawn_paper()
	await get_tree().create_timer(wait_time).timeout

	moving_part.position.y = initial_position
	_is_pressed = false
