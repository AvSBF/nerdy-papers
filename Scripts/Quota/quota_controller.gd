extends CanvasLayer

@onready var value_label : Label = $Panel/Margin/VBox/TopRow/Value
@onready var progress_bar : ProgressBar = $Panel/Margin/VBox/Progress

var _round : Node

func _ready():
	_round = get_tree().get_first_node_in_group("round_controller")
	if _round != null:
		_round.deposits_changed.connect(_on_deposits_changed)
		_update_label()

func _on_deposits_changed(_total_deposited: int, _buff_threshold: int) -> void:
	_update_label()

func _update_label():
	value_label.text = "%d / %d" % [_round.total_deposited, _round.quota_target]
	progress_bar.max_value = _round.quota_target
	progress_bar.value = _round.total_deposited
