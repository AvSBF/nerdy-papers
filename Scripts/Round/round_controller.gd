extends Node

signal deposits_changed(current_deposited: int, required_for_buff: int)
signal buff_required_reached
signal quota_reached

@export var required_min : int = 3
@export var required_max : int = 6
@export var difficulty_increase_multiplier : float = 1.1
@export var quota_increase_multiplier_range : Vector2

var current_deposited : int = 0
var current_required_for_buff : int = 0

var current_quota : int = 3

func _ready() -> void:
	current_quota = 3
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)
	roll_required()
	quota_reached.connect(quota_change_required)

func _on_paper_deposited(_count: int) -> void:
	current_deposited += 1
	deposits_changed.emit(current_deposited, current_required_for_buff)
	if current_deposited >= current_required_for_buff:
		buff_required_reached.emit()
	if current_deposited >= current_quota:
		quota_reached.emit()

func roll_required() -> void:
	current_required_for_buff += randi_range(required_min * difficulty_increase_multiplier, required_max * difficulty_increase_multiplier)

func quota_change_required():
	current_quota *= randf_range(quota_increase_multiplier_range.x,quota_increase_multiplier_range.y)
