extends Node3D

@export var paper_scene : PackedScene
@export var variation_x : Vector2
@export var variation_y : Vector2

@export var initial_center_pos : Vector3 = Vector3(-0.8,4.356,0)

func spawn_paper() -> void:
	var paper := paper_scene.instantiate()
	add_child(paper)
	paper.position = _get_random_position()

func _get_random_position() -> Vector3:
	var new_pos := initial_center_pos
	new_pos.x += randf_range(variation_x.x,variation_x.y)
	new_pos.z += randf_range(variation_y.x,variation_y.y)
	return new_pos
