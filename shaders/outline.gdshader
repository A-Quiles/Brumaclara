shader_type spatial;
// Full-screen pass drawn by the main camera: darkens the pixels on the near side of a depth jump,
// giving all geometry the thick dark silhouettes of the reference art. Sprites are transparent,
// so they are not in the depth texture and keep their own hand-drawn outlines.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.11, 0.07, 0.05, 1.0);
uniform float threshold = 0.06;  // relative depth jump that counts as an edge

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);  // a 1x1 quad covering the whole screen
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float depth = texture(depth_texture, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 ndc = vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
#else
	vec4 ndc = vec4(uv * 2.0 - 1.0, depth, 1.0);
#endif
	vec4 view = inv_projection * ndc;
	return -view.z / view.w;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float centre = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	float farthest = max(
			max(linear_depth(SCREEN_UV + vec2(px.x, 0.0), INV_PROJECTION_MATRIX),
				linear_depth(SCREEN_UV - vec2(px.x, 0.0), INV_PROJECTION_MATRIX)),
			max(linear_depth(SCREEN_UV + vec2(0.0, px.y), INV_PROJECTION_MATRIX),
				linear_depth(SCREEN_UV - vec2(0.0, px.y), INV_PROJECTION_MATRIX)));
	ALBEDO = line_color.rgb;
	ALPHA = (farthest - centre) / centre > threshold ? 1.0 : 0.0;
}
