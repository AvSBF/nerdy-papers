extends Node

signal target_changed(target: Node)

const GROUPS : Array[String] = ["button", "door"]

@export var interaction_distance : float = 3.0
@export_flags_3d_physics var interaction_mask : int = 0xFFFFFFFF

@onready var player : CharacterBody3D = get_parent()
@onready var camera : Camera3D = player.get_node("Camera3D")

var current_target : Node = null

func _physics_process(_delta: float) -> void:
	var target := _find_target()
	if target == current_target:
		return
	current_target = target
	target_changed.emit(current_target)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_with_current()

func interact_with_current() -> void:
	if current_target == null:
		return
	if current_target.is_in_group("button"):
		_on_button_interacted(current_target)
	elif current_target.is_in_group("door"):
		_on_door_interacted(current_target)

func _find_target() -> Node:
	return InteractionRaycast.get_node_in_front(
		camera,
		interaction_distance,
		func(node : Node) -> bool:
			for group in GROUPS:
				if node.is_in_group(group):
					return true
			return false,
		interaction_mask
	)

func _on_button_interacted(button: Node) -> void:
	button.interact()

func _on_door_interacted(door: Node) -> void:
	door.open()
