shader_type spatial;
uniform sampler2D reference_photo : source_color, filter_linear_mipmap;
uniform vec3 part_center;
uniform vec3 part_size;
uniform vec4 fur : source_color = vec4(.40,.39,.45,1.);
varying vec3 wolf_point;
void vertex(){
	wolf_point = VERTEX * part_size + part_center;
}
void fragment(){
	vec2 image_uv = vec2(.721 + wolf_point.x*.81, .480-(wolf_point.y-.28)*.56);
	vec3 paint = texture(reference_photo,image_uv).rgb;
	float face = smoothstep(.23,.49,-wolf_point.z);
	float edge = 1.0-smoothstep(.155,.211,abs(wolf_point.x));
	float valid = smoothstep(.038,.11,max(paint.r,max(paint.g,paint.b)));
	ALBEDO = mix(fur.rgb,paint,face*edge*valid);
	ROUGHNESS = .81;
}
