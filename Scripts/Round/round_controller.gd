extends Node

signal deposits_changed(total_deposited: int, buff_threshold: int)
signal buff_required_reached
signal quota_reached

@export var buff_threshold_range : Vector2 = Vector2(3, 5)
@export var quota_growth_range : Vector2

var total_deposited : int = 0
var buff_threshold : int = 0

var quota_target : int = 3

func _ready() -> void:
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)
	quota_reached.connect(quota_change_required)
	reset_round()

func reset_round() -> void:
	quota_target = 3
	total_deposited = 0
	buff_threshold = 0
	roll_required()

func _on_paper_deposited(_count: int) -> void:
	total_deposited += 1
	deposits_changed.emit(total_deposited, buff_threshold)
	if total_deposited >= buff_threshold:
		buff_required_reached.emit()
	if total_deposited >= quota_target:
		quota_reached.emit()

func roll_required() -> void:
	buff_threshold += randi_range(buff_threshold_range.x, buff_threshold_range.y)
	deposits_changed.emit(total_deposited, buff_threshold)

func quota_change_required():
	var increment := int(quota_target * randf_range(quota_growth_range.x, quota_growth_range.y))
	quota_target = total_deposited + increment
	deposits_changed.emit(total_deposited, buff_threshold)

func add_deposits(amount: int) -> void:
	for i in amount:
		_on_paper_deposited(1)

func complete_quota() -> void:
	add_deposits(quota_target - total_deposited)

func next_quota_stage() -> void:
	quota_change_required()
