extends Node3D

@onready var detect_area : Area3D = $DetectArea
@onready var count_label : Label3D = $CountLabel

var count : int = 0

func _ready() -> void:
	detect_area.body_entered.connect(_on_body_entered)
	_update_label()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("paper"):
		return
	count += 1
	body.queue_free()
	_update_label()

func _update_label() -> void:
	count_label.text = str(count)