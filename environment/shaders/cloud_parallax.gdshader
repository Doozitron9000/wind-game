shader_type canvas_item;

uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform vec2 world_size = vec2(4096.0, 2048.0);
uniform vec2 wind_offset = vec2(0.0, 0.0);
uniform sampler2D cloud_map;

varying float v_depth;
varying vec2 v_uv_offset;

void vertex() {
    v_depth = INSTANCE_CUSTOM.r;
    v_uv_offset = vec2(INSTANCE_CUSTOM.g, INSTANCE_CUSTOM.b);
    float depth = 1.0 - INSTANCE_CUSTOM.r;
    
    float scale = INSTANCE_CUSTOM.r;
    VERTEX *= scale;
    
    VERTEX += wind_offset * (1.0 - depth);
    VERTEX += camera_offset * depth;
    
    vec2 half_size = world_size * 0.5;
    VERTEX = mod(VERTEX + half_size, world_size) - half_size;
}

void fragment() {
    vec2 uv_offset = v_uv_offset;
    vec2 uv_size = uv_offset.x < 0.5 ? vec2(0.5, 0.25) : vec2(0.5, 0.5);
    vec2 final_uv = uv_offset + (1.0 - UV) * uv_size;
    COLOR = texture(cloud_map, final_uv);
}
