extends CanvasLayer

signal card_chosen(card_type: String)

@export var card_scene : PackedScene
@export var required_min : int = 3
@export var required_max : int = 6

const GOOD_POOL : Array[Dictionary] = [
	{"title": "Лёгкие ноги", "desc": "Заглушка. Скорость пока не меняется."},
	{"title": "Сильный бросок", "desc": "Заглушка. Дальность броска пока не меняется."},
	{"title": "Второе дыхание", "desc": "Заглушка. Ничего пока не даёт."},
]

const BAD_POOL : Array[Dictionary] = [
	{"title": "Тяжёлые руки", "desc": "Заглушка. Скорость пока не меняется."},
	{"title": "Дрожь в руках", "desc": "Заглушка. Точность пока не меняется."},
	{"title": "Туман в голове", "desc": "Заглушка. Ничего пока не отнимает."},
]

@onready var overlay : Control = $Overlay
@onready var cards_container : HBoxContainer = $Overlay/Center/Cards

var _deposits_total : int = 0
var _required : int = 0
var _cards_active : bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)
	_roll_required()

func _on_paper_deposited(_count: int) -> void:
	if _cards_active:
		return
	_deposits_total += 1
	if _deposits_total >= _required:
		_show_cards()

func _roll_required() -> void:
	_required = randi_range(required_min, required_max)

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
	_hide_cards()

func _hide_cards() -> void:
	overlay.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_deposits_total = 0
	_roll_required()
	_cards_active = false