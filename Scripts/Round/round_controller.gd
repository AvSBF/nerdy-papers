extends Node

signal deposits_changed(current_deposited: int, required_for_buff: int)
signal buff_required_reached

@export var required_min : int = 3
@export var required_max : int = 6
@export var current_quota : int = 100

var current_deposited : int = 0
var current_required_for_buff : int = 0

func _ready() -> void:
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)
	roll_required()

func _on_paper_deposited(_count: int) -> void:
	current_deposited += 1
	deposits_changed.emit(current_deposited, current_required_for_buff)
	if current_deposited >= current_required_for_buff:
		buff_required_reached.emit()

func roll_required() -> void:
	current_required_for_buff += randi_range(required_min, required_max)