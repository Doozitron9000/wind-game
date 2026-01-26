shader_type canvas_item;

uniform sampler2D cloud_meta;

const float LAYERS = 32.0;
const float LAYERS_RECIPROCAL = 0.03125;

void fragment() {
	// get the depth layer we are looking at
	float depth = floor(UV.y * LAYERS) + 1.0;
	
	// get our v
	float v = (depth - 0.5) * LAYERS_RECIPROCAL;
	// get our u
	float u = UV.x * (1.0 - (depth * LAYERS_RECIPROCAL));
	
    vec4 meta = texture(cloud_meta, vec2(u, v));
    COLOR = vec4(meta.r, meta.g, 0.0, 1.0);
}