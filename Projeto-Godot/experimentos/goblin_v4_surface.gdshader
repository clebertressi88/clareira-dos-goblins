shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

// Textura procedural independente de UV. Nao altera ossos, geometria ou animacoes.
uniform vec4 tint : source_color = vec4(0.52, 0.62, 0.41, 1.0);
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.82;
uniform float surface_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float grain_scale : hint_range(1.0, 180.0) = 35.0;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.12;
uniform float fleck_strength : hint_range(0.0, 0.3) = 0.06;
uniform float scratch_strength : hint_range(0.0, 0.25) = 0.0;
varying vec3 local_position;

float rand3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(
        mix(mix(rand3(i),rand3(i+vec3(1.0,0.0,0.0)),f.x),
            mix(rand3(i+vec3(0.0,1.0,0.0)),rand3(i+vec3(1.0,1.0,0.0)),f.x),f.y),
        mix(mix(rand3(i+vec3(0.0,0.0,1.0)),rand3(i+vec3(1.0,0.0,1.0)),f.x),
            mix(rand3(i+vec3(0.0,1.0,1.0)),rand3(i+vec3(1.0,1.0,1.0)),f.x),f.y),
        f.z);
}

void vertex() {
    local_position = VERTEX;
}

void fragment() {
    float macro = noise3(local_position * (grain_scale * 0.19));
    float pores = noise3(local_position * grain_scale);
    float fine = noise3(local_position * (grain_scale * 3.3));
    float leather_lines = noise3(vec3(local_position.x * 16.0,local_position.y * 100.0,local_position.z * 20.0));
    float scratches = smoothstep(0.79, 0.96, leather_lines) * scratch_strength;
    float speckle = smoothstep(0.74, 0.93, fine) * fleck_strength;
    float tone = 1.0 + (macro - 0.5) * grain_strength * 1.6
        + (pores - 0.5) * grain_strength * 0.8 - speckle - scratches;
    ALBEDO = clamp(tint.rgb * tone, vec3(0.0), vec3(1.0));
    ROUGHNESS = clamp(surface_roughness + (pores - 0.5)*0.10 + scratches*0.35, 0.05, 1.0);
    METALLIC = surface_metallic;
}
