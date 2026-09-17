extends Node
class_name PlayerInteractor

signal target_changed(target: Node)
signal held_paper_changed(paper: Node)

const GROUPS : Array[String] = ["button", "paper"]

const PICKUP_TIME : float = 0.15
const STACK_SPACING : float = 0.05
const STACK_BASE_Y : float = 0.55
const RISE_TIME : float = 0.15

@export var interaction_distance : float = 3.0
@export var throw_speed : float = 5.0
@export_flags_3d_physics var interaction_mask : int = 0xFFFFFFFF

@onready var player : CharacterBody3D = get_parent()
@onready var camera : Camera3D = player.get_node("Camera3D")
@onready var hold_point : Node3D = camera.get_node("HoldPoint")
@onready var _round : RoundController

var current_target : Node = null
var held_papers : Array[Paper] = []
var max_held_papers : int = 1
var _flying_paper : Paper = null
var _throwing : bool = false

func _ready():
	_round = get_tree().get_first_node_in_group("round_controller")

func _physics_process(_delta: float) -> void:
	_update_target()

func _update_target() -> void:
	var target := _find_target()
	if target == current_target:
		return
	_set_target_highlight(current_target, false)
	current_target = target
	_set_target_highlight(current_target, true)
	target_changed.emit(current_target)

func _set_target_highlight(node: Node, on: bool) -> void:
	if node != null and node.is_in_group("paper"):
		var paper := node as Paper
		if paper:
			paper.set_highlighted(on)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_with_current()
	elif event.is_action_pressed("throw"):
		_throw_current()

func interact_with_current() -> void:
	if _flying_paper != null or _throwing:
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
	if body == null or _flying_paper != null or _throwing or held_papers.size() >= (max_held_papers + _round.additional_held_papers):
		return
	_flying_paper = body
	body.set_highlighted(false)
	body.hold_offset = _stack_offset_for_index(held_papers.size())
	body.set_show_label_while_held(held_papers.size() == 0)
	body.picked_up.connect(_on_paper_picked_up, CONNECT_ONE_SHOT)
	body.pick_up(hold_point, PICKUP_TIME)

func _on_paper_picked_up(paper: Paper) -> void:
	if _flying_paper != paper:
		return
	_flying_paper = null
	held_papers.append(paper)
	_update_held_stack()
	held_paper_changed.emit(paper)

func _stack_offset_for_index(i: int) -> Vector3:
	if i <= 0:
		return Vector3.ZERO
	return Vector3(0, -STACK_BASE_Y - (i - 1) * STACK_SPACING, 0)

func _update_held_stack() -> void:
	for i in held_papers.size():
		var paper := held_papers[i]
		var target_offset := _stack_offset_for_index(i)
		if i == held_papers.size() - 1:
			paper.hold_offset = target_offset
		else:
			create_tween().tween_property(paper, "hold_offset", target_offset, 0.12)
		paper.set_show_label_while_held(i == 0)

func _throw_current() -> void:
	if held_papers.is_empty() or _throwing:
		return
	_throw_top_paper()

func _throw_top_paper() -> void:
	_throwing = true
	var paper := held_papers.pop_front() as Paper
	held_paper_changed.emit(null)
	_update_held_labels()

	if is_instance_valid(paper):
		paper.drop(-camera.global_transform.basis.z * throw_speed)

	if not held_papers.is_empty():
		var tween := create_tween()
		for i in held_papers.size():
			var p := held_papers[i]
			tween.parallel().tween_property(p, "hold_offset", _stack_offset_for_index(i), RISE_TIME)
	_throwing = false

func _update_held_labels() -> void:
	for i in held_papers.size():
		held_papers[i].set_show_label_while_held(i == 0)

func discard_all_papers() -> void:
	var papers := held_papers.duplicate()
	held_papers.clear()
	_flying_paper = null
	held_paper_changed.emit(null)
	for paper in papers:
		if is_instance_valid(paper):
			paper.queue_free()
