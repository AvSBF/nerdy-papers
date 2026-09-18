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
# скорость броска
var additional_throw_speed : float = 0
const THROW_STEP : float = 1.0
# кулдаун кнопки-раздатчика
var button_cooldown_multiplier : float = 1.0
# магнит к правильной урне
var magnet_strength : float = 0.0
# комбо за серию точных бросков
var combo_enabled : bool = false
var combo_streak : int = 0
const COMBO_THRESHOLD : int = 3
# подсветка правильной урны
var hint_enabled : bool = false
# инверсия камеры
var invert_look : bool = false
# тряска камеры
var camera_shake_strength : float = 0.0
# пикселизация картинки
var pixelation_amount : float = 0.0
# движущийся прицел
var crosshair_strength : float = 0.0
# случайный эффект (жёлтая карточка)
const RANDOM_POOL : Array[String] = [
	"extra_points",
	"movement_speed_positive",
	"movement_speed_negative",
	"quota_change_positive",
	"quota_change_negative",
	"more_hands",
	"less_hands",
	"interaction_range_positive",
	"interaction_range_negative",
	"power_throw",
	"weak_throw",
	"automation",
	"stingy_points",
	"magnet",
	"combo",
	"hint",
	"inversion",
	"disable_inversion",
	"camera_shake",
	"pixelation",
	"moving_crosshair",
]

func _ready() -> void:
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)
		storage.wrong_paper.connect(_on_wrong_paper)
	quota_reached.connect(quota_change_required)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var interactor := player.get_node("Interactor")
		if interactor != null:
			interactor.held_paper_changed.connect(_on_held_changed)
	reset_round()

func reset_round() -> void:
	quota_target = 3
	total_deposited = 0
	buff_threshold = 0
	roll_required()

func _on_paper_deposited(_count: int) -> void:
	combo_streak += 1
	var bonus := 0
	if combo_enabled and combo_streak >= COMBO_THRESHOLD:
		bonus = 1
	total_deposited += points_per_paper + bonus
	deposits_changed.emit(total_deposited, buff_threshold)
	if total_deposited >= buff_threshold:
		buff_required_reached.emit()
	if total_deposited >= quota_target:
		quota_reached.emit()

func _on_wrong_paper() -> void:
	combo_streak = 0

func _on_held_changed(paper: Node) -> void:
	var wanted := -1
	if paper != null:
		wanted = paper.get_paper_type()
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.set_hint(hint_enabled and storage.paper_type == wanted)

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
		"less_hands":
			additional_held_papers = max(0, additional_held_papers - 1)
		"interaction_range_positive":
			additional_interaction_distance += INTERACTION_STEP
		"interaction_range_negative":
			additional_interaction_distance = max(0, additional_interaction_distance - INTERACTION_STEP)
		"power_throw":
			additional_throw_speed += THROW_STEP
		"weak_throw":
			additional_throw_speed = max(-3.0, additional_throw_speed - THROW_STEP)
		"automation":
			button_cooldown_multiplier = maxf(0.5, button_cooldown_multiplier * 0.7)
		"stingy_points":
			points_per_paper = maxi(1, points_per_paper - 1)
		"magnet":
			magnet_strength += 2.0
		"combo":
			combo_enabled = true
		"hint":
			hint_enabled = true
		"inversion":
			invert_look = true
		"disable_inversion":
			invert_look = false
		"camera_shake":
			camera_shake_strength += 1.0
		"pixelation":
			pixelation_amount = minf(0.9, pixelation_amount + 0.2)
		"moving_crosshair":
			crosshair_strength += 1.0
		"random":
			apply_buff(str(RANDOM_POOL.pick_random()))
	return