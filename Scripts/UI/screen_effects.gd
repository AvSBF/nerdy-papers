extends CanvasLayer

var _round : Node
var _mat : ShaderMaterial
var _crosshair : ColorRect
var _crosshair_pos : Vector2 = Vector2.ZERO
var _crosshair_target : Vector2 = Vector2.ZERO
var _crosshair_retarget : float = 0.0

func _ready() -> void:
	_round = get_tree().get_first_node_in_group("round_controller")
	var rect := $EffectsRect as ColorRect
	_mat = rect.material as ShaderMaterial
	var player := get_tree().current_scene.get_node("Player")
	_crosshair = player.get_node("UI/Crosshair") as ColorRect

func _process(_delta: float) -> void:
	var amount : float = _round.pixelation_amount
	$EffectsRect.visible = amount > 0.0
	if _mat != null:
		_mat.set_shader_parameter("pixel_size", amount * 14.0)
	_update_crosshair(_delta)

func _update_crosshair(_delta: float) -> void:
	if _crosshair == null:
		return
	var strength : float = _round.crosshair_strength
	if strength <= 0.0:
		_crosshair_pos = Vector2.ZERO
		_apply_crosshair_pos()
		return
	_crosshair_retarget -= _delta
	if _crosshair_retarget <= 0.0:
		_crosshair_target = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 18.0
		_crosshair_retarget = randf_range(0.12, 0.35)
	var to_target := _crosshair_target - _crosshair_pos
	if to_target.length() < 2.0:
		_crosshair_pos = _crosshair_target
	else:
		var speed := 90.0 * strength
		_crosshair_pos += to_target.normalized() * speed * _delta
	_apply_crosshair_pos()

func _apply_crosshair_pos() -> void:
	_crosshair.offset_left = -3.0 + _crosshair_pos.x
	_crosshair.offset_right = 3.0 + _crosshair_pos.x
	_crosshair.offset_top = -3.0 + _crosshair_pos.y
	_crosshair.offset_bottom = 3.0 + _crosshair_pos.y