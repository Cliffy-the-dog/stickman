shader_type canvas_item;

uniform bool is_unlocked = false;
uniform float u_time = 0.0;

group_uniforms Locked_State;
uniform vec4 locked_grey : source_color = vec4(0.15, 0.17, 0.2, 0.5);
uniform vec4 locked_lime : source_color = vec4(0.3, 0.95, 0.3, 0.85);
uniform vec4 locked_cyan : source_color = vec4(0.0, 0.85, 0.95, 0.85);

group_uniforms Fire_State;
uniform vec4 fire_outer : source_color = vec4(0.9, 0.15, 0.0, 0.95);
uniform vec4 fire_inner : source_color = vec4(1.0, 0.55, 0.0, 1.0);
uniform vec4 fire_core  : source_color = vec4(1.0, 0.98, 0.75, 1.0);

group_uniforms Controls;
uniform float flow_speed : hint_range(0.5, 6.0) = 3.0;
uniform float flame_tongues : hint_range(2.0, 15.0) = 7.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec2 uv = UV;
	float t = u_time * flow_speed;

	float vert_dist = abs(uv.y - 0.5);
	float border_fade = smoothstep(0.5, 0.35, vert_dist);
	float end_fade = clamp(sin(uv.x * 3.14159) * 4.0, 0.0, 1.0);

	if (!is_unlocked) {
		float pulse = sin(uv.x * 8.0 - t * 3.0) * 0.5 + 0.5;
		float core_mask = smoothstep(0.25, 0.0, vert_dist);

		vec4 pulse_color = mix(locked_cyan, locked_lime, pulse);
		vec4 final_color = mix(locked_grey, pulse_color, core_mask * pulse);

		COLOR = final_color;
		COLOR.a *= (smoothstep(0.4, 0.0, vert_dist) * 0.4 + core_mask * 0.6) * end_fade * border_fade;

	} else {
		float core_intensity = smoothstep(0.2, 0.0, vert_dist);

		vec2 tongue_uv = vec2(
			uv.x * flame_tongues - t * 2.0, 
			(uv.y - 0.5) * 3.0 + sin(uv.x * 6.0 + t * 4.0) * 0.3
		);
		float tongues = pow(noise(tongue_uv), 1.6) * 1.6;

		float heat = core_intensity * 0.8 + (1.0 - vert_dist * 2.0) * 0.3 + tongues * (1.0 - vert_dist * 1.5);
		heat = clamp(heat, 0.0, 1.6);

		vec4 fire_color;
		if (heat > 0.95) {
			fire_color = mix(fire_inner, fire_core, (heat - 0.95) / 0.65);
		} else if (heat > 0.35) {
			fire_color = mix(fire_outer, fire_inner, (heat - 0.35) / 0.6);
		} else {
			fire_color = fire_outer;
		}

		float alpha = smoothstep(0.18, 0.42, heat);

		COLOR = fire_color;
		COLOR.a *= alpha * end_fade * border_fade;
	}
}