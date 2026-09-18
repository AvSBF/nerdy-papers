extends CharacterBody3D
class_name PlayerController

@export var move_speed : float = 5.0
@export var sprint_multiplier : float = 1.8
@export var mouse_sensitivity : float = 0.003
@export var min_pitch : float = -80.0
@export var max_pitch : float = 80.0

@onready var interactor : PlayerInteractor = $Interactor
@onready var player_movement : PlayerMovement = $"PlayerMovement"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
