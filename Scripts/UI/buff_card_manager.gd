extends CanvasLayer

signal card_chosen(card_type: String)

@export var card_scene : PackedScene

const GOOD_POOL : Array[Dictionary] = [
	{"title": "Extra points", "desc": "Each paper gives +1 extra point", "buff_id" : "extra_points"},
	{"title": "Speed Change", "desc": "Adds 0.25 to movement speed", "buff_id" : "movement_speed_positive"},
	{"title": "Quota Change", "desc": "Now you need less papers for quota", "buff_id" : "quota_change_positive"},
	{"title": "One More Hand?", "desc": "Someone behind you gives you more hands to hold your papers", "buff_id" : "more_hands"},
	{"title": "Arm length", "desc": "Wow! You've got long arms now", "buff_id" : "interaction_range_positive"},
	{"title": "Magnet", "desc": "Papers are attracted to the correct bin", "buff_id" : "magnet"},
	{"title": "Strong Throw", "desc": "Papers fly faster", "buff_id" : "power_throw"},
	{"title": "Automation", "desc": "The paper button works faster", "buff_id" : "automation"},
	{"title": "Combo", "desc": "A streak of correct throws gives bonus points", "buff_id" : "combo"},
	{"title": "Hint", "desc": "The correct bin is highlighted", "buff_id" : "hint"},
	{"title": "Clear Inversion", "desc": "Removes inverted camera", "buff_id" : "disable_inversion"},
]

const BAD_POOL : Array[Dictionary] = [
	{"title": "Speed Change", "desc": "Takes 0.5 from movement speed", "buff_id" : "movement_speed_negative"},
	{"title": "Quota Change", "desc": "Now you need even more papers for quota", "buff_id" : "quota_change_negative"},
	{"title": "Where is my arm", "desc": "Someone cut off your extra arm. Now you can hold less papers at once", "buff_id" : "less_hands"},
	{"title": "Arm length", "desc": "T-Rex move for arms. Less interaction distance.", "buff_id" : "interaction_range_negative"},
	{"title": "Weak Throw", "desc": "Papers fly slower", "buff_id" : "weak_throw"},
	{"title": "Stingy Points", "desc": "Each paper gives one point less", "buff_id" : "stingy_points"},
	{"title": "Inversion", "desc": "Your camera axes are inverted", "buff_id" : "inversion"},
	{"title": "Camera Shake", "desc": "The camera shakes harder each time", "buff_id" : "camera_shake"},
	{"title": "Pixelation", "desc": "The picture gets more pixelated", "buff_id" : "pixelation"},
	{"title": "Moving Crosshair", "desc": "Your crosshair moves chaotically", "buff_id" : "moving_crosshair"},
]

const YELLOW_POOL : Array[Dictionary] = [
	{"title": "Mystery", "desc": "Random effect - could be good or bad", "buff_id" : "random"},
]

@onready var overlay : Control = $Overlay
@onready var cards_container : HBoxContainer = $Overlay/Center/Panel/VBox/Cards

var _round : RoundController
var _cards_active : bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	_round = get_tree().get_first_node_in_group("round_controller")
	if _round != null:
		_round.buff_required_reached.connect(_on_buff_required)

func _on_buff_required() -> void:
	if _cards_active:
		return
	_show_cards()

func force_show() -> void:
	_show_cards()

func _show_cards() -> void:
	_cards_active = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_cards()
	overlay.visible = true

func _build_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	var types := ["green", "red", "green"]
	if randf() < 0.4:
		for i in types.size():
			if types[i] == "green":
				types[i] = "yellow"
				break
	types.shuffle()
	var used_good : Array[int] = []
	var used_bad : Array[int] = []
	var used_yellow : Array[int] = []

	for t in types:
		var card := card_scene.instantiate() as BuffCard
		cards_container.add_child(card)
		var used : Array[int] = used_good if t == "green" else (used_bad if t == "red" else used_yellow)
		card.setup(_random_buff(t, used))
		card.pressed.connect(_on_card_pressed.bind(card))

func _random_buff(type: String, used: Array[int]) -> Dictionary:
	var pool : Array[Dictionary] = GOOD_POOL if type == "green" else (BAD_POOL if type == "red" else YELLOW_POOL)
	var index := randi_range(0, pool.size() - 1)
	while index in used:
		index = randi_range(0, pool.size() - 1)
	used.append(index)
	var data : Dictionary = pool[index].duplicate()
	data["type"] = type
	return data

func _on_card_pressed(card: BuffCard) -> void:
	card_chosen.emit(card.card_type)
	if _round != null:
		if !card.buff_id.is_empty():
			_round.apply_buff(card.buff_id)
		_round.roll_required()
	_hide_cards()

func _hide_cards() -> void:
	overlay.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_cards_active = false
