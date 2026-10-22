shader_type spatial;
// Ground of a hillside town: grass on gentle ground, rock where it gets steep, and the streets,
// yards and gardens painted from a mask (r cobble, g dirt, b garden soil, a forest floor). Borders
// between materials wander by whole texels so they never end in a straight line.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D grass : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D rock : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D cobble : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D dirt : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D soil : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D forest : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D paths : filter_linear;  // the mask, covering `area`
uniform vec4 area = vec4(-44.0, -54.0, 88.0, 98.0);  // x, z, width, depth
uniform float tile = 5.45;
uniform float texels = 20.0;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 cell = floor(world_pos.xz * texels) / texels;  // whole texels
	float wobble = noise(cell * 1.3) - 0.5;
	vec2 uv = world_pos.xz / tile;
	vec3 colour = texture(grass, uv).rgb;
	vec4 mask = texture(paths, (cell - area.xy) / area.zw);
	float edge = 0.5 + wobble * 0.5;  // ragged borders
	if (mask.a > edge) colour = texture(forest, uv).rgb;
	if (mask.b > edge) colour = texture(soil, uv).rgb;
	if (mask.g > edge) colour = texture(dirt, uv).rgb;
	if (mask.r > edge) colour = texture(cobble, uv).rgb;
	float steep = 1.0 - world_normal.y;
	bool paved = max(mask.r, mask.g) > edge;
	if (!paved && steep > 0.13 + wobble * 0.08) {  // worn earth where the slope gets steeper
		colour = texture(dirt, uv).rgb;
	}
	if (steep > 0.24 + wobble * 0.1) {  // bare rock on the steep parts, seen from the side
		vec2 side = abs(world_normal.x) > abs(world_normal.z) ? world_pos.zy : world_pos.xy;
		colour = texture(rock, side * vec2(1.0, -1.0) / tile).rgb;
	}
	colour *= 1.0 - steep * 0.8;  // slopes in shade read as relief
	ALBEDO = colour;
	ROUGHNESS = 1.0;
}
