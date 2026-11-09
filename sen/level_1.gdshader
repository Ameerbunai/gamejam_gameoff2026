
shader_type spatial;
render_mode cull_back;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 0.15) = 0.035;
uniform vec3 glass_tint : source_color = vec3(1.0, 0.75, 0.25);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.4;

varying vec3 vertex_pos;
varying vec3 obj_norm;
varying vec3 obj_campos;

void vertex() {
	vertex_pos = VERTEX;
	obj_norm = NORMAL;
	obj_campos = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
	vec3 ray_dir = normalize(vertex_pos - obj_campos);
	ray_dir = refract(ray_dir, obj_norm, 0.9);

	vec3 tmax3 = (sign(ray_dir) * 0.5 - obj_campos) / ray_dir;
	float t_exit = min(min(tmax3.x, tmax3.y), tmax3.z);
	vec3 exit_pos = obj_campos + ray_dir * t_exit;

	vec3 exit_normal = vec3(0.0);

	if (abs(exit_pos.x - 0.5) < 1e-4) exit_normal = vec3(1, 0, 0);
	else if (abs(exit_pos.x + 0.5) < 1e-4) exit_normal = vec3(-1, 0, 0);
	else if (abs(exit_pos.y - 0.5) < 1e-4) exit_normal = vec3(0, 1, 0);
	else if (abs(exit_pos.y + 0.5) < 1e-4) exit_normal = vec3(0, -1, 0);
	else if (abs(exit_pos.z - 0.5) < 1e-4) exit_normal = vec3(0, 0, 1);
	else exit_normal = vec3(0, 0, -1);

	vec3 backface_norm = normalize((MODEL_MATRIX * vec4(exit_normal, 0.0)).xyz);
	vec2 refraction = refract(backface_norm, obj_norm, 0.9).xy * 0.1;

	vec2 uv = SCREEN_UV + refraction;

	// Frosted glass blur
	vec3 seethru = vec3(0.0);

	seethru += texture(SCREEN_TEXTURE, uv + vec2(blur_strength, 0.0)).rgb;
	seethru += texture(SCREEN_TEXTURE, uv + vec2(-blur_strength, 0.0)).rgb;
	seethru += texture(SCREEN_TEXTURE, uv + vec2(0.0, blur_strength)).rgb;
	seethru += texture(SCREEN_TEXTURE, uv + vec2(0.0, -blur_strength)).rgb;
	seethru += texture(SCREEN_TEXTURE, uv).rgb;

	seethru /= 5.0;

	// Yellow tint
	seethru = mix(seethru, seethru * glass_tint, tint_strength);

	ALBEDO = mix(COLOR.rgb, seethru, 0.75);

	ROUGHNESS = 0.8;
	SPECULAR = 0.5;
}
