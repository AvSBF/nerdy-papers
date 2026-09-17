extends Node
class_name PlayerMovement

@onready var player : CharacterBody3D = get_parent()
@onready var controller : Node = player

var camera : Camera3D
var round_controller : RoundController

func _ready() -> void:
	camera = player.get_node("Camera3D")
	round_controller = get_tree().get_first_node_in_group("round_controller")

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
	speed = max(1, speed + round_controller.current_additional_speed)
	
	player.velocity = move_dir * speed
	player.move_and_slide()
