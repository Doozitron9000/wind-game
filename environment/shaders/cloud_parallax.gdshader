shader_type canvas_item;

// The camera offset for parallax effect, set from the script
uniform vec2 camera_offset = vec2(0.0, 0.0);
// The size of the world for wrapping clouds, set from the script
uniform vec2 world_size = vec2(4096.0, 2048.0);
// The wind offset for moving clouds, accumulated over time in the script
uniform vec2 wind_offset = vec2(0.0, 0.0);
// The cloud texture atlas, with different cloud shapes
uniform sampler2D cloud_map;

// Varying variables to pass data from vertex to fragment shader
// v_depth: The depth of the cloud instance, used for parallax and scaling
varying float v_depth;
// v_uv_offset: The UV offset for sampling the cloud texture, based on instance data
varying vec2 v_uv_offset;
// v_seed: A seed value for procedural animation
varying float v_seed;

void vertex() {
    // first set the varying variables based on the instance custom data
    v_seed = INSTANCE_CUSTOM.a;
    v_depth = INSTANCE_CUSTOM.r;
    v_uv_offset = vec2(INSTANCE_CUSTOM.g, INSTANCE_CUSTOM.b);

    // get the depth. We want it to be 0 for the closest clouds and 1 for the farthest, so we invert the r value
    float depth = 1.0 - INSTANCE_CUSTOM.r;
    // scale the cloud based on depth
    float scale = INSTANCE_CUSTOM.r;

    // use the scale, wind offset, and camera offset to calculate the final vertex position
    VERTEX *= scale;
    VERTEX += wind_offset * (1.0 - depth);
    VERTEX += camera_offset * depth;
    // wrap the clouds around the world size to create a seamless looping effect
    vec2 half_size = world_size * 0.5;
    VERTEX = mod(VERTEX + half_size, world_size) - half_size;
}

void fragment() {
    // Calculate the UV coordinates for sampling the cloud texture
    vec2 uv_offset = v_uv_offset;
    // All clouds are half the width of the texture, but the height is either 0.25 or 0.5
    // with the taller clouds being on the right half of the texture. 
    vec2 uv_size = uv_offset.x < 0.5 ? vec2(0.5, 0.25) : vec2(0.5, 0.5);
    vec2 final_uv = uv_offset + (1.0 - UV) * uv_size;
    // Add a small procedural warp to the UVs based on the seed
    float seed = v_seed;
    // The warp is a simple sine wave that moves over time based on the seed, creating a subtle
    // variation in the cloud shapes.
    vec2 warp = vec2(
        sin(final_uv.y * 10.0 + v_seed * 6.28 + TIME * 0.2) * 0.02,
        sin(final_uv.x * 10.0 + v_seed * 6.28 + TIME * 0.14) * 0.02
    );
    // Sample the cloud texture with the final UVs and apply the warp
    vec4 cloud = texture(cloud_map, final_uv + warp);
    // Only use the red channel for the cloud color, the alpha for transparency.
    // This leaves us two free channels we can later use.
    COLOR = vec4(cloud.r, cloud.r, cloud.r, cloud.a);
}
