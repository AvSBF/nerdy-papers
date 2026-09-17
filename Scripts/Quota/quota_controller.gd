extends CanvasLayer

@onready var quota_label : Label = $"Quota Detials"

var _round : Node

func _ready():
	_round = get_tree().get_first_node_in_group("round_controller")
	if _round != null:
		_round.deposits_changed.connect(_on_deposits_changed)
		_update_label()

func _on_deposits_changed(_current_deposited: int, _required_for_buff: int) -> void:
	_update_label()

func _update_label():
	quota_label.text = "%d / %d" % [_round.current_deposited, _round.current_quota]