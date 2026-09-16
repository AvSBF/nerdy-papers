extends CanvasLayer

@onready var panel : PanelContainer = $Panel
@onready var spawn_count_slider : HSlider = $Panel/Margin/VBox/SpawnRow/SpawnCountSlider
@onready var spawn_count_value : Label = $Panel/Margin/VBox/SpawnRow/SpawnCountValue
@onready var spawn_button : Button = $Panel/Margin/VBox/SpawnRow/SpawnButton
@onready var max_held_slider : HSlider = $Panel/Margin/VBox/MaxHeldRow/MaxHeldSlider
@onready var max_held_value : Label = $Panel/Margin/VBox/MaxHeldRow/MaxHeldValue
@onready var delete_button : Button = $Panel/Margin/VBox/DeleteButton

@onready var interactor : Node = get_tree().current_scene.get_node("Player/Interactor")

func _ready() -> void:
	panel.visible = false
	spawn_count_slider.value_changed.connect(_on_spawn_count_changed)
	max_held_slider.value_changed.connect(_on_max_held_changed)
	spawn_button.pressed.connect(_on_spawn_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	_on_spawn_count_changed(spawn_count_slider.value)
	_on_max_held_changed(max_held_slider.value)

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
