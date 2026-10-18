shader_type spatial;
// Pixel-art blocks (ground, walls, steps). Use with a unit BoxMesh scaled to the block size:
// the top face and the side faces get their own tiling texture, and the edges of the side faces
// get a dark outline so walls read like the hand-drawn reference.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D top_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D side_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec2 top_size = vec2(4.0, 4.0);   // world units covered by one top tile
uniform vec2 side_size = vec2(4.0, 2.0);  // world units covered by one side tile (along, down)
uniform bool top_local = false;           // map the top from the block's own corner (paths, rotated blocks)
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 edge_color : source_color = vec4(0.13, 0.08, 0.05, 1.0);
uniform float edge_width = 0.07;

varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 world_pos;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec3 half_size = 0.5 * scale;
	vec3 p = local_pos * scale;
	vec3 n = local_normal;
	vec3 color;
	if (n.y > 0.5) {
		vec2 uv = top_local ? p.xz + half_size.xz : world_pos.xz;
		color = texture(top_texture, uv / top_size).rgb;
	} else if (n.y < -0.5) {
		color = texture(side_texture, p.xz / side_size).rgb * 0.5;
	} else {
		// horizontal coordinate runs left to right as seen from outside the face
		float along;
		float width;
		if (abs(n.x) > 0.5) {
			along = n.x > 0.0 ? half_size.z - p.z : p.z + half_size.z;
			width = scale.z;
		} else {
			along = n.z > 0.0 ? p.x + half_size.x : half_size.x - p.x;
			width = scale.x;
		}
		float down = half_size.y - p.y;
		color = texture(side_texture, vec2(along, down) / side_size).rgb;
		float edge = min(min(along, width - along), min(down, scale.y - down));
		if (edge < edge_width) {
			color = edge_color.rgb;
		}
	}
	ALBEDO = color * tint.rgb;
	ROUGHNESS = 1.0;
}
