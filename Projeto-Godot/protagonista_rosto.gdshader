shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D portrait : source_color, filter_linear_mipmap;
uniform vec4 olive : source_color = vec4(0.50,0.55,0.29,1.0);
varying vec3 head_point;
void vertex(){
	head_point = VERTEX;
}
void fragment(){
	vec2 uv = vec2(0.496 + head_point.x * 0.900,
		0.356 - (head_point.y - 0.952) * 0.612);
	vec3 photo = texture(portrait,uv).rgb;
	float front = smoothstep(0.022,0.110,head_point.z);
	float rim = 1.0 - smoothstep(0.166,0.224,abs(head_point.x));
	float caps = smoothstep(0.954,0.991,head_point.y) * (1.0 - smoothstep(1.411,1.449,head_point.y));
	ALBEDO = mix(olive.rgb,photo,front * rim * caps);
	ROUGHNESS = 0.75;
}
