extends CanvasLayer

signal card_chosen(card_type: String)

@export var card_scene : PackedScene

const GOOD_POOL : Array[Dictionary] = [
	{"title": "Туман в голове", "desc": "Заглушка. Ничего пока не отнимает."},
	{"title": "Extra points", "desc": "Each paper gives +1 extra point", "buff_id" : "extra_points"},
	{"title": "Speed Increase", "desc": "Adds 0.25 to movement speed", "buff_id" : "movement_speed_positive"},
]

const BAD_POOL : Array[Dictionary] = [
	{"title": "Speed Decrease", "desc": "Takes 0.5 from movement speed", "buff_id" : "movement_speed_negative"},
	{"title": "Туман в голове", "desc": "Заглушка. Ничего пока не отнимает."},
	{"title": "Туман в голове", "desc": "Заглушка. Ничего пока не отнимает."},
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
	types.shuffle()
	var used_good : Array[int] = []
	var used_bad : Array[int] = []

	for t in types:
		var card := card_scene.instantiate() as BuffCard
		cards_container.add_child(card)
		card.setup(_random_buff(t, used_good if t == "green" else used_bad))
		card.pressed.connect(_on_card_pressed.bind(card))

func _random_buff(type: String, used: Array[int]) -> Dictionary:
	var pool : Array[Dictionary] = GOOD_POOL if type == "green" else BAD_POOL
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
