shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.5,0.65,0.4,1.0);
uniform float roughness_level : hint_range(0.0,1.0)=0.87;
uniform float grain_strength : hint_range(0.0,0.2)=0.07;
varying vec3 object_space;
float rand3(vec3 p) {
	return fract(sin(dot(p,vec3(37.719,91.137,13.531)))*43758.5453);
}
void vertex(){
	object_space=VERTEX;
}
void fragment(){
	float large = rand3(floor(object_space*6.0));
	float fine = rand3(floor(object_space*47.0));
	float fleck = (large*0.58+fine*0.42-0.5)*2.0;
	float modulation = 1.0+fleck*grain_strength;
	ALBEDO=tint.rgb*modulation;
	ROUGHNESS=clamp(roughness_level+(fine-.5)*.06,0.0,1.0);
	METALLIC=0.0;
	SPECULAR=0.3;
}
