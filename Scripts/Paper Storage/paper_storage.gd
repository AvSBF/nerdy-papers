extends Node3D

@onready var detect_area : Area3D = $DetectArea
@onready var count_label : Label3D = $CountLabel

@export var paper_type : int = 1
@export var throw_speed : float = 10.0

var count : int = 0

func _ready() -> void:
	detect_area.body_entered.connect(_on_body_entered)
	_update_label()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("paper"):
		return
	var is_same := _is_same_paper_type(body)
	if is_same:
		count += 1
		body.queue_free()
		_update_label()
	else:
		_throw_toward_player(body)

func _update_label() -> void:
	count_label.text = str(count)

func _is_same_paper_type(paper : Node3D) -> bool:
	return paper.get_paper_type() == paper_type

func _throw_toward_player(paper : Node3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dir := (player.global_position - paper.global_position).normalized()
	dir.y = absf(dir.y)
	paper.set_deferred("linear_velocity", dir * throw_speed)
