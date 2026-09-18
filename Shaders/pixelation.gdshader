shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(0.0, 16.0) = 0.1;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.06;

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 uv = floor(SCREEN_UV / px) * px + px * 0.5;
	vec3 col = texture(SCREEN_TEXTURE, uv).rgb;

	float n = fract(sin(dot(SCREEN_UV * TIME, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * grain_strength;

	COLOR = vec4(col, 1.0);
}