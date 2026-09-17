class_name PaperOutline
extends MeshInstance3D

@export var thickness : Vector3 = Vector3(0.06, 0.15, 0.06)

func _ready() -> void:
	visible = false
	scale = Vector3.ONE + thickness

func set_highlighted(on: bool) -> void:
	visible = on
