extends Node

@onready var player : CharacterBody3D = get_parent()
@onready var controller : Node = player

var camera : Camera3D

func _ready() -> void:
	camera = player.get_node("Camera3D")

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("key_left", "key_right"),
		Input.get_axis("key_backwards", "key_forward")
	)

	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var move_dir := (right * direction.x + forward * direction.z)

	var speed = controller.move_speed
	if Input.is_action_pressed("sprint"):
		speed *= controller.sprint_multiplier

	player.velocity = move_dir * speed
	player.move_and_slide()
