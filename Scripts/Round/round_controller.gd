extends Node
class_name RoundController

signal deposits_changed(total_deposited: int, buff_threshold: int)
signal buff_required_reached
signal quota_reached

@export var buff_threshold_range : Vector2 = Vector2(3, 5)
@export var quota_growth_range : Vector2

var total_deposited : int = 0
var buff_threshold : int = 0
var quota_target : int = 3

# баффы
# очки за бумажку
var points_per_paper : int = 1
# дополнительная скорость
var current_additional_speed : float = 0
# количество предметов в руках
var additional_held_papers : int = 0
# длина подбора
var additional_interaction_distance : float = 0
const INTERACTION_STEP : float = 0.25

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
	total_deposited += points_per_paper
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

func apply_buff(buff_id : String):
	match buff_id:
		"extra_points":
			points_per_paper += 1
		"movement_speed_positive":
			current_additional_speed += 0.25
		"movement_speed_negative":
			current_additional_speed -= 0.5
		"quota_change_positive":
			var cut := randi_range(30,70)
			quota_target = maxi(total_deposited + 1, quota_target - cut)
			deposits_changed.emit(total_deposited, buff_threshold)
		"quota_change_negative":
			quota_target += randi_range(30,70)
			deposits_changed.emit(total_deposited, buff_threshold)
		"more_hands":
			additional_held_papers += 1
			additional_held_papers = max(0,additional_held_papers)
		"less_hands":
			additional_held_papers -= 1
			additional_held_papers = max(0,additional_held_papers)
		"interaction_range_positive":
			additional_interaction_distance += INTERACTION_STEP
		"interaction_range_negative":
			additional_interaction_distance -= INTERACTION_STEP
			additional_interaction_distance = max(0,additional_interaction_distance)
	return
