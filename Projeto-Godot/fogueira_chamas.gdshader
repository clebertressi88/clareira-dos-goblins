shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_add, fog_disabled;

uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
		mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float h = 1.0 - UV.y;
	float time = TIME + seed;
	float turbulence = noise(vec2(UV.x * 7.0 + seed, h * 5.0 - time * 3.0));
	float sway = sin(time * 4.1 + h * 7.0) * h * 0.075;
	float center = UV.x - 0.5 + sway;
	float width = (1.0 - h) * 0.35 + 0.015;
	float body = 1.0 - smoothstep(width * 0.40, width, abs(center) + turbulence * 0.11);
	float tips = 1.0 - smoothstep(0.54 + turbulence * 0.31, 0.78 + turbulence * 0.21, h);
	float core = clamp((1.0 - h) * body + turbulence * 0.16, 0.0, 1.0);
	ALBEDO = mix(vec3(0.78, 0.10, 0.012), vec3(1.0, 0.55, 0.10), smoothstep(0.10, 0.52, core));
	ALBEDO = mix(ALBEDO, vec3(1.0, 0.94, 0.57), smoothstep(0.52, 0.90, core));
	ALPHA = body * tips * smoothstep(0.0, 0.085, h) * 0.68;
}
