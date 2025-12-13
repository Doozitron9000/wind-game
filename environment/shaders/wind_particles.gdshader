shader_type canvas_item;

// particle size consts
const float MIN_SIZE = 0.5;
const float MAX_SIZE = 1.8;
// max alpha the particle can have adnt he amount all alpha is multiplied by
const float MAX_ALPHA = 0.75;
// particle length modifier
const float STRETCH_MOD = 0.3;

// The texture to serve as the mask for these particles
uniform sampler2D mask_tex;
// the size and position of the mask bounds
uniform vec2 bounds_pos;
uniform vec2 bounds_size;
// the current wind vector
uniform float wind_speed;
// the position of the fragment in world space
varying vec2 world_pos;
// the depth of the given particle
varying float z;

void vertex() {
	// resize the particles based on their depth
	z = INSTANCE_CUSTOM.z;
	float base_size = mix(MIN_SIZE, MAX_SIZE, z);

	// stretch the particles making them at least 1.0 unit long
	float stretch = 1.0 + wind_speed * STRETCH_MOD;

	// scale in local space
	VERTEX.x *= base_size * stretch; // along wind
	VERTEX.y *= base_size;           // across wind
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
	// while also accounting for the texture's alpha
    float tex_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(1.0, 1.0, 1.0, mask * z * MAX_ALPHA * tex_alpha);
}