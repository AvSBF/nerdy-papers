extends Node

signal target_changed(target: Node)
signal held_paper_changed(paper: Node)

const GROUPS : Array[String] = ["button", "paper"]

const PICKUP_TIME : float = 0.15

@export var interaction_distance : float = 3.0
@export var throw_speed : float = 5.0
@export_flags_3d_physics var interaction_mask : int = 0xFFFFFFFF

@onready var player : CharacterBody3D = get_parent()
@onready var camera : Camera3D = player.get_node("Camera3D")
@onready var hold_point : Node3D = camera.get_node("HoldPoint")

var current_target : Node = null
var held_paper : Paper = null
var _flying_paper : Paper = null

func _physics_process(_delta: float) -> void:
	_update_target()

func _update_target() -> void:
	var target := _find_target()
	if target == current_target:
		return
	current_target = target
	target_changed.emit(current_target)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_with_current()
	elif event.is_action_pressed("throw"):
		_throw_current()

func interact_with_current() -> void:
	if held_paper != null or _flying_paper != null:
		return
	if current_target == null:
		return
	if current_target.is_in_group("button"):
		_on_button_interacted(current_target)
	elif current_target.is_in_group("paper"):
		_on_paper_interacted(current_target)

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

func _on_paper_interacted(paper: Node) -> void:
	var body := paper as Paper
	if body == null or _flying_paper != null:
		return
	_flying_paper = body
	body.picked_up.connect(_on_paper_picked_up, CONNECT_ONE_SHOT)
	body.pick_up(hold_point, PICKUP_TIME)

func _on_paper_picked_up(paper: Paper) -> void:
	if _flying_paper != paper:
		return
	_flying_paper = null
	held_paper = paper
	held_paper_changed.emit(held_paper)

func _throw_current() -> void:
	if held_paper == null:
		return
	_drop_paper()

func _drop_paper() -> void:
	var paper := held_paper
	held_paper = null
	held_paper_changed.emit(null)
	paper.drop(-camera.global_transform.basis.z * throw_speed)
