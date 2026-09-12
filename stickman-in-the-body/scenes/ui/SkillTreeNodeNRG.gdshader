shader_type canvas_item;

// --- INSPECTOR VARIABLES ---
group_uniforms Flame_Appearance;
uniform sampler2D noise_texture : repeat_enable, hint_default_black;
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);     // Inside hot core color
uniform vec4 outer_color : source_color = vec4(0.5, 0.0, 1.0, 1.0);    // Outer flame tip color
uniform float flame_density : hint_range(0.5, 5.0, 0.1) = 1.5;         // Overall size/thickness of flames
uniform float center_hollow : hint_range(0.0, 0.5, 0.01) = 0.05;       // Keeps the absolute center clean

group_uniforms Flame_Dynamics;
uniform float expansion_speed : hint_range(0.1, 5.0, 0.1) = 1.2;      // Speed of outward burst
uniform float swirl_amount : hint_range(-5.0, 5.0, 0.1) = 1.5;         // Twists the flames as they expand
uniform float distortion : hint_range(0.0, 1.0, 0.05) = 0.25;          // How jagged/chaotic the shapes are

group_uniforms Masking;
uniform float edge_fade : hint_range(0.01, 0.5, 0.01) = 0.1;           // Smooth cutoff at the ColorRect borders

void fragment() {
    // 1. Center coordinates so (0,0) is the middle of the ColorRect
    vec2 center_uv = UV - vec2(0.5);
    float dist = length(center_uv);
    float angle = atan(center_uv.y, center_uv.x);
    
    // 2. Square Boundary Mask (Prevents flames from clipping uglily at the ColorRect edges)
    vec2 border_dist = min(UV, vec2(1.0) - UV);
    float square_mask = smoothstep(0.0, edge_fade, min(border_dist.x, border_dist.y));
    
    // 3. Simple distortion pass to break up straight lines
    vec2 distort_uv = vec2(angle / (2.0 * 3.14159), dist - (TIME * 0.2));
    float raw_distortion = texture(noise_texture, distort_uv).r;
    float modified_angle = angle + (raw_distortion - 0.5) * distortion;
    
    // 4. Transform coordinates to burst radially outward from the core
    // X handles the circumferential wrap around the square, Y drives the outward explosion over TIME
    vec2 flame_uv_a = vec2(modified_angle / (2.0 * 3.14159) + (TIME * swirl_amount * 0.05), dist - (TIME * expansion_speed));
    vec2 flame_uv_b = vec2(-modified_angle / (2.0 * 3.14159) - (TIME * swirl_amount * 0.02), dist * 1.3 - (TIME * expansion_speed * 1.2));
    
    // 5. Sample the noise texture using the outward vector streams
    float noise_a = texture(noise_texture, flame_uv_a).r;
    float noise_b = texture(noise_texture, flame_uv_b).r;
    float final_flame = (noise_a * noise_b) * flame_density;
    
    // 6. Apply the center hollow and edge constraints
    float life_mask = smoothstep(center_hollow, center_hollow + 0.1, dist) * square_mask;
    final_flame *= life_mask;
    
    // 7. Crisp thresholding for stylized anime flame edges
    float alpha_cutoff = smoothstep(0.15, 0.35, final_flame);
    float core_cutoff = smoothstep(0.4, 0.65, final_flame);
    
    // 8. Composition
    vec3 final_color = mix(outer_color.rgb, core_color.rgb, core_cutoff);
    COLOR = vec4(final_color, alpha_cutoff);
}
