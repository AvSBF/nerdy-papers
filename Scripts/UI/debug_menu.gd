extends CanvasLayer

@onready var panel : PanelContainer = $Panel
@onready var spawn_count_slider : HSlider = $Panel/Margin/VBox/SpawnRow/SpawnCountSlider
@onready var spawn_count_value : Label = $Panel/Margin/VBox/SpawnRow/SpawnCountValue
@onready var spawn_button : Button = $Panel/Margin/VBox/SpawnRow/SpawnButton
@onready var max_held_slider : HSlider = $Panel/Margin/VBox/MaxHeldRow/MaxHeldSlider
@onready var max_held_value : Label = $Panel/Margin/VBox/MaxHeldRow/MaxHeldValue
@onready var delete_button : Button = $Panel/Margin/VBox/DeleteButton
@onready var force_cards_button : Button = $Panel/Margin/VBox/ForceCardsButton
@onready var deposit_count_slider : HSlider = $Panel/Margin/VBox/DepositRow/DepositCountSlider
@onready var deposit_count_value : Label = $Panel/Margin/VBox/DepositRow/DepositCountValue
@onready var deposit_button : Button = $Panel/Margin/VBox/DepositRow/DepositButton
@onready var complete_quota_button : Button = $Panel/Margin/VBox/CompleteQuotaButton
@onready var next_quota_button : Button = $Panel/Margin/VBox/NextQuotaButton
@onready var buff_option : OptionButton = $Panel/Margin/VBox/BuffRow/BuffOption
@onready var apply_buff_button : Button = $Panel/Margin/VBox/BuffRow/ApplyBuffButton

@onready var interactor : Node = get_tree().current_scene.get_node("Player/Interactor")
@onready var round : Node = get_tree().current_scene.get_node("Round Controller")

const BUFFS : Array[Dictionary] = [
	{"id": "extra_points", "label": "Extra Points"},
	{"id": "movement_speed_positive", "label": "Light Legs"},
	{"id": "movement_speed_negative", "label": "Heavy Legs"},
	{"id": "quota_change_positive", "label": "Economy"},
	{"id": "quota_change_negative", "label": "Greed"},
	{"id": "more_hands", "label": "More Hands"},
	{"id": "less_hands", "label": "Fewer Hands"},
	{"id": "interaction_range_positive", "label": "Long Arms"},
	{"id": "interaction_range_negative", "label": "Short Arms"},
	{"id": "power_throw", "label": "Strong Throw"},
	{"id": "weak_throw", "label": "Weak Throw"},
	{"id": "automation", "label": "Automation"},
	{"id": "stingy_points", "label": "Stingy Points"},
	{"id": "magnet", "label": "Magnet"},
	{"id": "combo", "label": "Combo"},
	{"id": "hint", "label": "Hint"},
	{"id": "inversion", "label": "Inversion"},
	{"id": "disable_inversion", "label": "Clear Inversion"},
	{"id": "camera_shake", "label": "Camera Shake"},
	{"id": "pixelation", "label": "Pixelation"},
	{"id": "moving_crosshair", "label": "Moving Crosshair"},
	{"id": "random", "label": "Random Buff (yellow)"},
]

func _ready() -> void:
	panel.visible = false
	spawn_count_slider.value_changed.connect(_on_spawn_count_changed)
	max_held_slider.value_changed.connect(_on_max_held_changed)
	spawn_button.pressed.connect(_on_spawn_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	force_cards_button.pressed.connect(_on_force_cards_pressed)
	deposit_count_slider.value_changed.connect(_on_deposit_count_changed)
	deposit_button.pressed.connect(_on_deposit_pressed)
	complete_quota_button.pressed.connect(_on_complete_quota_pressed)
	next_quota_button.pressed.connect(_on_next_quota_pressed)
	apply_buff_button.pressed.connect(_on_apply_buff_pressed)
	_populate_buff_option()
	_on_spawn_count_changed(spawn_count_slider.value)
	_on_max_held_changed(max_held_slider.value)
	_on_deposit_count_changed(deposit_count_slider.value)

func _populate_buff_option() -> void:
	buff_option.clear()
	for i in BUFFS.size():
		var buff : Dictionary = BUFFS[i]
		buff_option.add_item("%s (%s)" % [buff.label, buff.id], i)
		buff_option.set_item_metadata(i, buff.id)

func _on_apply_buff_pressed() -> void:
	if round == null:
		return
	var buff_id : String = buff_option.get_selected_metadata()
	round.apply_buff(buff_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		_toggle_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and panel.visible:
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_spawn_count_changed(value: float) -> void:
	spawn_count_value.text = str(int(value))

func _on_max_held_changed(value: float) -> void:
	max_held_value.text = str(int(value))
	interactor.max_held_papers = int(value)

func _on_spawn_pressed() -> void:
	var creator := get_tree().current_scene.find_child("Paper Creator", true, false)
	if creator == null:
		return
	var amount := int(spawn_count_slider.value)
	for i in amount:
		creator.spawn_paper()

func _on_delete_pressed() -> void:
	interactor.discard_all_papers()
	for paper in get_tree().get_nodes_in_group("paper"):
		if is_instance_valid(paper):
			paper.queue_free()

func _on_force_cards_pressed() -> void:
	var buff_ui := get_tree().current_scene.get_node("BuffCardUI") as Node
	if buff_ui != null and buff_ui.has_method("force_show"):
		buff_ui.force_show()

func _on_deposit_count_changed(value: float) -> void:
	deposit_count_value.text = str(int(value))

func _on_deposit_pressed() -> void:
	if round != null:
		round.add_deposits(int(deposit_count_slider.value))

func _on_complete_quota_pressed() -> void:
	if round != null:
		round.complete_quota()

func _on_next_quota_pressed() -> void:
	if round != null:
		round.next_quota_stage()
