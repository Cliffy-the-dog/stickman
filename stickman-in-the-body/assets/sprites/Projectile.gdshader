shader_type canvas_item;

void fragment() {
    // Force the UV to repeat horizontally across the length of the line
    vec2 tiled_uv = vec2(UV.x * 10.0, UV.y); 
    COLOR = texture(TEXTURE, tiled_uv);
}