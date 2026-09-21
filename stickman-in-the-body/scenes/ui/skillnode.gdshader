shader_type canvas_item;

// Unpaused animation time — driven by SkillNode._process via elapsed_time (not built-in TIME).

// --- INSPECTOR PARAMETERS ---
group_uniforms Flame_Colors;
uniform vec4 flame_base_color : source_color = vec4(0.2, 0.0, 0.4, 1.0); // Dark outer aura shroud
uniform vec4 flame_mid_color : source_color = vec4(0.6, 0.0, 1.0, 1.0);  // Vibrant cursed purple energy
uniform vec4 flame_core_color : source_color = vec4(0.9, 0.8, 1.0, 1.0); // White-hot center crackle

group_uniforms Flame_Shape_And_Speeds;
uniform sampler2D noise_texture : repeat_enable, hint_default_black;
uniform float expansion_speed : hint_range(0.1, 3.0, 0.05) = 0.6; // Kept relatively low to keep it clean
uniform float swirl_speed : hint_range(-3.0, 3.0, 0.05) = 0.4;     // Gentle circular torque
uniform float flame_scale : hint_range(0.1, 4.0, 0.1) = 1.2;       // Controls size of flame tendrils

group_uniforms Performance_Trimming;
uniform float center_hollow_radius : hint_range(0.0, 0.4, 0.01) = 0.08; // Keeps center clean for icon visibility
uniform float edge_fade_width : hint_range(0.01, 0.3, 0.01) = 0.06;      // Smooth edge lock

uniform float elapsed_time = 0.0;
uniform bool is_owned = false;

group_uniforms Owned_Orange;
uniform vec4 owned_base_color : source_color = vec4(0.55, 0.12, 0.0, 1.0);
uniform vec4 owned_mid_color : source_color = vec4(1.0, 0.45, 0.0, 1.0);
uniform vec4 owned_core_color : source_color = vec4(1.0, 0.85, 0.35, 1.0);

void fragment() {
    // 1. Establish center vectors
    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv);
    float angle = atan(center_uv.y, center_uv.x);

    // 2. Continuous Fluid Wave Matrix (Gives smooth flow instead of jittery noise)
    float flow_time = elapsed_time * expansion_speed;
    mat2 wave_rotation = mat2(
        vec2(cos(elapsed_time * swirl_speed), -sin(elapsed_time * swirl_speed)), 
        vec2(sin(elapsed_time * swirl_speed), cos(elapsed_time * swirl_speed))
    );
    vec2 rotated_uv = (wave_rotation * center_uv) + vec2(0.5);

    // 3. Create radial flow coordinates
    vec2 polar_uv_a = vec2(angle / (2.0 * 3.14159) + (elapsed_time * swirl_speed * 0.1), dist * flame_scale - flow_time);
    vec2 polar_uv_b = vec2(-angle / (2.0 * 3.14159) - (elapsed_time * swirl_speed * 0.05), dist * (flame_scale * 1.4) - (flow_time * 1.2));

    // 4. Sample and cross-multiply noise layers for smooth tendril intersections
    float layer_a = texture(noise_texture, polar_uv_a).r;
    float layer_b = texture(noise_texture, polar_uv_b).r;
    float combined_flame = (layer_a * layer_b) * 2.5;

    // 5. Clean Masks (Stops clipping, leaves space for skill text/icon)
    vec2 border_dist = min(UV, vec2(1.0) - UV);
    float square_bounds = smoothstep(0.0, edge_fade_width, min(border_dist.x, border_dist.y));
    float center_hole = smoothstep(center_hollow_radius, center_hollow_radius + 0.08, dist);
    combined_flame *= square_bounds * center_hole;

    // 6. Smooth Step Thresholding (3 Tier Color Mixing for that polished look)
    float base_mask = smoothstep(0.12, 0.25, combined_flame);
    float mid_mask = smoothstep(0.30, 0.50, combined_flame);
    float core_mask = smoothstep(0.55, 0.80, combined_flame);

    // 7. Compose Colors Smoothly (orange when the player already owns this skill)
    vec4 base_c = is_owned ? owned_base_color : flame_base_color;
    vec4 mid_c = is_owned ? owned_mid_color : flame_mid_color;
    vec4 core_c = is_owned ? owned_core_color : flame_core_color;

    vec4 final_color = mix(vec4(0.0), base_c, base_mask);
    final_color = mix(final_color, mid_c, mid_mask);
    final_color = mix(final_color, core_c, core_mask);
    COLOR = final_color;
}
