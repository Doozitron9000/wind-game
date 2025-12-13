shader_type canvas_item;

// only consider every nth pixel when sampling
const float skip = 2.0;
// the number of pixels to sample either side of the current one
const int sample_radius = 10;

void fragment() {
    vec2 uv = UV;
    vec2 t = TEXTURE_PIXEL_SIZE;

    float sum = 0.0;
    float weight = 0.0;

	// iterate through neighboring pixels to determine this pixel's final weight
    for (int i = -sample_radius; i <= sample_radius; i++) {
		// get how much the currently sampled pixels should weigh
		// in our final calculation weighing closer pixels more than
		// distant onces
        float w = 1.0 - abs(float(i)) / float(sample_radius);
		// now find the pixel being sampled, get its r value (this is a
		// grescale map so any one channel will do) and multiply it by how much
		// this pixel weighs in our current calcultion before adding it to our
		// sum
        sum += texture(TEXTURE, uv + vec2(t.x * skip * float(i), 0.0)).r * w;
		// make sure to update weight
        weight += w;
    }
	
	// now we can just get our weighted average to determine the final color
	// of this pixel
    float v = sum / weight;
    COLOR = vec4(v, v, v, 1.0);
}