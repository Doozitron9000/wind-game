shader_type canvas_item;

// The texture to serve as the mask for these particles
uniform sampler2D mask_tex;
// the size and position of the mask bounds
uniform vec2 bounds_pos;
uniform vec2 bounds_size;
// the position of the fragment in world space
varying vec2 world_pos;

void vertex() {
    // determine the world space position
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    // Convert world position to the space of the uv mask
    vec2 mask_uv = (world_pos - bounds_pos) / bounds_size;

	// get the transparency value of the current pixel
	// since the reference image is black and white we just use the
	// r channel for this
    float mask = texture(mask_tex, mask_uv).r;
	// now set the particle's transparency based on the above mask value
    COLOR = vec4(1.0, 1.0, 1.0, mask);
}