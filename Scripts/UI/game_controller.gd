extends CanvasLayer

enum State { MENU, PLAYING, PAUSED, DEFEAT }

var _state : int = State.MENU

@onready var main_menu : Control = $MainMenu
@onready var pause_menu : Control = $PauseMenu
@onready var defeat_screen : Control = $DefeatScreen
@onready var timer_label : Label = $TimerLabel

var _round : Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_round = get_tree().get_first_node_in_group("round_controller")
	if _round != null:
		_round.quota_timeout.connect(_on_quota_timeout)
	main_menu.get_node("Center/Panel/VBox/PlayButton").pressed.connect(_play)
	pause_menu.get_node("Center/Panel/VBox/ContinueButton").pressed.connect(_resume)
	pause_menu.get_node("Center/Panel/VBox/RestartButton").pressed.connect(_restart)
	pause_menu.get_node("Center/Panel/VBox/MenuButton").pressed.connect(_to_menu)
	defeat_screen.get_node("Center/Panel/VBox/RestartButton").pressed.connect(_restart)
	defeat_screen.get_node("Center/Panel/VBox/MenuButton").pressed.connect(_to_menu)
	_show_state(State.MENU)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if _state == State.PLAYING and _round != null:
		var m := int(_round.quota_time_left / 60.0)
		var s := int(fmod(_round.quota_time_left, 60.0))
		timer_label.text = "%02d:%02d" % [m, s]

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var buff_ui := get_tree().current_scene.get_node("BuffCardUI")
	if buff_ui != null and buff_ui._cards_active:
		return
	if _state == State.PLAYING:
		_pause()
	elif _state == State.PAUSED:
		_resume()

func _show_state(state: int) -> void:
	_state = state
	main_menu.visible = state == State.MENU
	pause_menu.visible = state == State.PAUSED
	defeat_screen.visible = state == State.DEFEAT
	timer_label.visible = state == State.PLAYING

func _play() -> void:
	_show_state(State.PLAYING)
	if _round != null:
		_round.start_round()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	_show_state(State.PAUSED)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	_show_state(State.PLAYING)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _restart() -> void:
	_play()

func _to_menu() -> void:
	_show_state(State.MENU)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_quota_timeout() -> void:
	_show_state(State.DEFEAT)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE