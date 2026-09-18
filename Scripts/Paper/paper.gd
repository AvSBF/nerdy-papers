class_name Paper
extends RigidBody3D

@export var paper_type : int = 1

signal picked_up(paper: Paper)

const KILL_Y : float = -0.5
const MAGNET_RADIUS : float = 8.0
const MAGNET_AIM_HEIGHT : float = 1.1
const MAGNET_RAMP_TIME : float = 1.5
const MAGNET_K : float = 0.5
const MAGNET_DAMPING : float = 2.0
const FACE_PLAYER_BASIS := Basis(Vector3(1.0, 0.0, 0.0), PI / 2.0)

const TYPE_COLORS : Array[Color] = [
	Color(0.20, 0.45, 0.90),
	Color(0.25, 0.75, 0.35),
	Color(0.95, 0.40, 0.70),
	Color(0.85, 0.25, 0.25),
]

@onready var type_label : Label3D = $TypeLabel
@onready var outline : PaperOutline = $Outline
@onready var color_square : MeshInstance3D = $ColorSquare

func _ready() -> void:
	type_label.text = str(paper_type)
	type_label.visible = false
	continuous_cd = true
	_apply_type_color()

func _apply_type_color() -> void:
	var mat := StandardMaterial3D.new()
	var color := TYPE_COLORS[clampi(paper_type - 1, 0, TYPE_COLORS.size() - 1)]
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	color_square.material_override = mat

func set_highlighted(on: bool) -> void:
	outline.set_highlighted(on)

var _flight_target : Node3D = null
var _hold_point : Node3D = null
var _flight_from : Vector3 = Vector3.ZERO
var _flight_from_basis : Basis = Basis.IDENTITY
var _flight_progress : float = 0.0
var _flight_time : float = 0.0
var _held : bool = false
var _is_player_thrown : bool = false
var _free_flight_time : float = 0.0
var hold_offset : Vector3 = Vector3.ZERO
var show_label_while_held : bool = true

func set_show_label_while_held(value: bool) -> void:
	show_label_while_held = value
	type_label.visible = false

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
	_is_player_thrown = false
	_free_flight_time = 0.0
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
	_is_player_thrown = true
	_free_flight_time = 0.0

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
		var target_basis : Basis = _flight_target.global_basis * FACE_PLAYER_BASIS if hold_offset == Vector3.ZERO else Basis.IDENTITY
		tform.basis = _flight_from_basis.slerp(target_basis, t)
		state.transform = tform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO

		if _flight_progress >= 1.0:
			_held = true
			_flight_target = null
			type_label.visible = false
			picked_up.emit(self)
	elif _held and _hold_point != null:
		var tform := _hold_point.global_transform
		tform.origin += _hold_point.global_basis * hold_offset
		tform.basis = _hold_point.global_basis * FACE_PLAYER_BASIS if hold_offset == Vector3.ZERO else Basis.IDENTITY
		state.transform = tform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
	else:
		_apply_magnet(state)

func _apply_magnet(state: PhysicsDirectBodyState3D) -> void:
	if not _is_player_thrown:
		return
	var round_ctrl := get_tree().get_first_node_in_group("round_controller")
	if round_ctrl == null or round_ctrl.magnet_strength <= 0.0:
		return
	var target := _nearest_correct_storage()
	if target == null:
		return
	var from := state.transform.origin
	var aim := target.global_position + Vector3(0, MAGNET_AIM_HEIGHT, 0)
	var offset := aim - from
	var dist := offset.length()
	if dist > MAGNET_RADIUS:
		return
	if state.linear_velocity.length() < 1.0:
		return
	_free_flight_time += state.step
	var ramp : float = clampf(_free_flight_time / MAGNET_RAMP_TIME, 0.0, 1.0)
	var k : float = round_ctrl.magnet_strength * MAGNET_K * ramp
	var spring := offset * k
	var damping := -state.linear_velocity * MAGNET_DAMPING
	state.apply_central_force(spring + damping)

func _nearest_correct_storage() -> Node3D:
	var best : Node3D = null
	var best_dist := INF
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		if storage.paper_type != paper_type:
			continue
		var d := global_position.distance_to(storage.global_position)
		if d < best_dist:
			best_dist = d
			best = storage
	return best
