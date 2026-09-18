extends Node3D
class_name PaperStorage

signal paper_deposited(count: int)
signal wrong_paper

@onready var detect_area : Area3D = $DetectArea
@onready var count_label : Label3D = $CountLabel
@onready var type_label : Label3D = $TypeLabel

@export var paper_type : int = 1
@export var throw_speed : float = 10.0
@export var plus_one_label_scene : PackedScene
@export var label_spawn_position : Vector3 = Vector3(0, 1.75, 0)

const LABEL_MOVE_TIME : float = 0.6
const LABEL_HOLD_TIME : float = 1.0
const LABEL_FADE_TIME : float = 0.3

var count : int = 0

func _ready() -> void:
	add_to_group("paper_storage")
	detect_area.body_entered.connect(_on_body_entered)
	type_label.text = str(paper_type)
	_update_label()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("paper"):
		return
	var is_same := _is_same_paper_type(body)
	if is_same:
		count += 1
		body.queue_free()
		_update_label()
		_spawn_plus_one_label()
		paper_deposited.emit(count)
	else:
		_throw_toward_player(body)
		wrong_paper.emit()

func _spawn_plus_one_label() -> void:
	if plus_one_label_scene == null:
		return
	var label := plus_one_label_scene.instantiate()
	label.position = label_spawn_position
	label.scale = Vector3.ZERO
	add_child(label)

	var target_offset := Vector3(
		randf_range(-0.1, 0.1),
		randf_range(0.1, 0.2),
		0.0
	)
	var target_position := label_spawn_position + target_offset
	label.rotation.z = atan2(target_offset.x, target_offset.y)

	var anim_player := label.get_node("AnimationPlayer") as AnimationPlayer
	anim_player.play("+1 label appear")

	var move_tween := create_tween()
	move_tween.tween_property(label, "position", target_position, LABEL_MOVE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await anim_player.animation_finished
	await get_tree().create_timer(LABEL_HOLD_TIME).timeout

	var fade_tween := create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, LABEL_FADE_TIME)
	await fade_tween.finished
	label.queue_free()

func _update_label() -> void:
	count_label.text = str(count)

func set_hint(on: bool) -> void:
	type_label.modulate = Color(0.2, 1.0, 0.4) if on else Color.WHITE

func _is_same_paper_type(paper : Node3D) -> bool:
	return paper.get_paper_type() == paper_type

func _throw_toward_player(paper : Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dir := (player.global_position - paper.global_position).normalized()
	dir.y = absf(dir.y)
	paper.set_deferred("linear_velocity", dir * throw_speed)
