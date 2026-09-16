class_name Paper
extends RigidBody3D

@export var paper_type : int = 1

signal picked_up(paper: Paper)

const KILL_Y : float = -0.5

@onready var type_label : Label3D = $TypeLabel

func _ready() -> void:
	type_label.text = str(paper_type)
	type_label.visible = false

var _flight_target : Node3D = null
var _hold_point : Node3D = null
var _flight_from : Vector3 = Vector3.ZERO
var _flight_from_basis : Basis = Basis.IDENTITY
var _flight_progress : float = 0.0
var _flight_time : float = 0.0
var _held : bool = false
var hold_offset : Vector3 = Vector3.ZERO
var show_label_while_held : bool = true

func set_show_label_while_held(value: bool) -> void:
	show_label_while_held = value
	if _held:
		type_label.visible = value

func get_paper_type() -> int :
	return paper_type

func pick_up(target: Node3D, flight_time: float) -> void:
	set_meta("pickup_layer", collision_layer)
	set_meta("pickup_mask", collision_mask)
	collision_layer = 0
	collision_mask = 0
	gravity_scale = 0.0
	can_sleep = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_held = false
	_flight_target = target
	_hold_point = target
	_flight_from = global_position
	_flight_from_basis = global_basis
	_flight_progress = 0.0
	_flight_time = flight_time

func drop(throw_velocity: Vector3) -> void:
	var hold_transform := global_transform
	reparent(get_tree().current_scene)
	global_transform = hold_transform
	_held = false
	_hold_point = null
	_flight_target = null
	show_label_while_held = true
	type_label.visible = false
	gravity_scale = 1.0
	can_sleep = true
	collision_layer = get_meta("pickup_layer", 1)
	collision_mask = get_meta("pickup_mask", 1)
	linear_velocity = throw_velocity

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if global_position.y < KILL_Y:
		print("найдена бумага под полом, удаление")
		queue_free()
		return
	if _flight_target != null:
		_flight_progress = minf(_flight_progress + state.step / _flight_time, 1.0)
		var t := ease(_flight_progress, 0.5)

		var target_pos := _flight_target.global_position + _flight_target.global_basis * hold_offset
		var tform := state.transform
		tform.origin = _flight_from.lerp(target_pos, t)
		tform.basis = _flight_from_basis.slerp(_flight_target.global_basis, t)
		state.transform = tform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO

		if _flight_progress >= 1.0:
			_held = true
			_flight_target = null
			type_label.visible = show_label_while_held
			picked_up.emit(self)
	elif _held and _hold_point != null:
		var tform := _hold_point.global_transform
		tform.origin += _hold_point.global_basis * hold_offset
		state.transform = tform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
