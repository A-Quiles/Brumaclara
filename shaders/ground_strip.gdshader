shader_type spatial;
// A flat strip of ground texture lying on the grass (a dirt road, a patch of cobbles or flowers).
// Its border wanders by whole texels so it never ends in a ruler-straight line.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D surface : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec2 size = vec2(4.0, 4.0);  // plane size in world units (x, z)
uniform float tile = 5.45;           // world size of one texture repeat
uniform float texels = 20.0;         // texels per world unit
uniform float ragged = 0.4;          // how far inward the border wanders, in world units
uniform bool across = false;         // rotate the texture 90 degrees (ruts running along x)
uniform bool oval = false;           // an oval patch instead of a strip
uniform bool world_uv = false;       // texture laid in world space, so overlapping pieces join seamlessly

varying vec2 local_pos;
varying vec3 world_pos;

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
	local_pos = VERTEX.xz;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz * texels) / texels;  // whole texels
	vec2 lp = floor(local_pos * texels) / texels;
	float inside = min(size.x * 0.5 - abs(lp.x), size.y * 0.5 - abs(lp.y));
	if (oval) {  // distance inside the ellipse, roughly in world units
		inside = (1.0 - length(lp / (size * 0.5))) * min(size.x, size.y) * 0.5;
	}
	if (inside < noise(cell * 1.7) * ragged) {
		discard;
	}
	vec2 uv = world_uv ? world_pos.xz / tile : (local_pos + size * 0.5) / tile;
	ALBEDO = texture(surface, across ? uv.yx : uv).rgb;
	ROUGHNESS = 1.0;
}
