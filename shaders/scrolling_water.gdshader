shader_type spatial;
// Unlit water: the texture scrolls along `flow` (falling sheets scroll down, the basin drifts slowly).
render_mode unshaded, cull_disabled;

uniform sampler2D water_texture : source_color, filter_nearest, repeat_enable;
uniform vec2 flow = vec2(0.0, 0.6);
uniform vec2 tiling = vec2(1.0, 1.0);

void fragment() {
	// snap the scroll to whole texels so the pixels never smear
	vec2 size = vec2(textureSize(water_texture, 0));
	vec2 offset = floor(flow * TIME * size) / size;
	vec4 water = texture(water_texture, UV * tiling - offset);
	ALBEDO = water.rgb;
	ALPHA = water.a;  // gaps between falling streams
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
