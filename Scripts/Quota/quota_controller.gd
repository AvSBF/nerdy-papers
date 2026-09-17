extends CanvasLayer

@onready var quota_label : Label = $"Quota Detials"

var current_quota : int
var current_deposited : int

func _ready():
	current_quota = 100
	current_deposited = 0
	for storage in get_tree().get_nodes_in_group("paper_storage"):
		storage.paper_deposited.connect(_on_paper_deposited)

func _on_paper_deposited(_count: int) -> void:
	current_deposited += 1
	_update_label()


func _update_label():
	quota_label.text = "%d / %d" % [current_deposited, current_quota]
