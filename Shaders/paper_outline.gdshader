shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

void fragment() {
	ALBEDO = vec3(1.0);
	ALPHA = 1.0;
}