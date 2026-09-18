extends CanvasLayer

var _round : Node
var _mat : ShaderMaterial

func _ready() -> void:
	_round = get_tree().get_first_node_in_group("round_controller")
	var rect := $FogRect as ColorRect
	_mat = rect.material as ShaderMaterial

func _process(_delta: float) -> void:
	var enabled : bool = _round != null and _round.fog_enabled
	$FogRect.visible = enabled
	if not enabled:
		return
	_mat.set_shader_parameter("jitter", Vector2(
		randf_range(-0.02, 0.02),
		randf_range(-0.02, 0.02)
	))
