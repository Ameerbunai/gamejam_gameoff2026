
shader_type spatial;

uniform vec3 concrete_color : source_color = vec3(0.48, 0.47, 0.43);
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float texture_scale : hint_range(1.0, 30.0) = 8.0;
uniform float bump_strength : hint_range(0.0, 1.0) = 0.25;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(
			mix(hash(i), hash(i + vec3(1,0,0)), f.x),
			mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x),
			f.y
		),
		mix(
			mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
			mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x),
			f.y
		),
		f.z
	);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 p = world_pos * texture_scale;

	float large_noise = noise(p * 0.2);
	float medium_noise = noise(p);
	float fine_noise = noise(p * 5.0);

	float concrete = large_noise * 0.45
		+ medium_noise * 0.4
		+ fine_noise * 0.15;

	ALBEDO = concrete_color * (0.72 + concrete * 0.55);

	float bumps = noise(p * 8.0);
	NORMAL = normalize(
		NORMAL + (vec3(bumps) - 0.5) * bump_strength
	);

	ROUGHNESS = roughness;
	SPECULAR = 0.15;
}
