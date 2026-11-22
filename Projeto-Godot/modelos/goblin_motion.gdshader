shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Material exclusivo por personagem: todos usam a textura original do GLB.
uniform sampler2D atlas_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 atlas_tint : source_color = vec4(1.0);
uniform float move_strength : hint_range(0.0, 1.0) = 0.0;
uniform float move_rate : hint_range(0.4, 3.0) = 1.0;
uniform float phase_offset = 0.0;

// O GLB fornecido nao possui armature/skinning. Deformacao leve por regiao
// cria passada de pernas, contrabalanco dos bracos e respiracao idle
// sem substituir a malha nem perder o atlas UV.
void vertex() {
	float phase = TIME * 7.0 * move_rate + phase_offset;
	float side = step(5.0, VERTEX.x);
	float swing = sin(phase + side * 3.14159265);
	float legs = 1.0 - smoothstep(-51.0, -35.0, VERTEX.y);
	float arms = smoothstep(-43.0, -32.0, VERTEX.y)
		* (1.0 - smoothstep(-17.0, -9.0, VERTEX.y))
		* smoothstep(11.0, 23.0, abs(VERTEX.x - 5.0));
	float upper = smoothstep(-44.0, -30.0, VERTEX.y);
	VERTEX.z += move_strength * (swing * 3.0 * legs - swing * 2.0 * arms);
	VERTEX.y += move_strength * max(0.0, swing) * 1.35 * legs;
	VERTEX.y += upper * sin(TIME * 1.7 + phase_offset) * 0.13;
}

void fragment() {
	vec4 texel = texture(atlas_texture, UV) * atlas_tint;
	ALBEDO = texel.rgb;
	ROUGHNESS = 0.78;
	METALLIC = 0.03;
}
