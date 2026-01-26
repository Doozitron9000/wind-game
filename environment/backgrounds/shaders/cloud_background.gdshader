shader_type canvas_item;

uniform sampler2D cloud_meta;
uniform sampler2D cloud_atlas;

const float LAYERS = 32.0;
const float LAYERS_RECIPROCAL = 0.03125;
const float WIDTH_RECIPROCAL = 0.0078125;

void fragment() {
	
	vec3 rgb = vec3(0.0);
	float a = 0.0;
	
	for (int i = 1; i <= 32; i++){
		// get the UV coords of the relevant metadata pixel to reference
		float metaV = (float(i)-0.5) * LAYERS_RECIPROCAL;
		float s = 1.0 - (float(i) * LAYERS_RECIPROCAL); // your perspective scale
		float metaU = UV.x * s + 0.5 * (1.0-s); // scale in to 0
		vec4 meta = texture(cloud_meta, vec2(metaU, metaV));
		float has_cloud = meta.r;
		float cloud_id  = meta.g;
		float cloudV = UV.y * 0.25 + cloud_id;
		float cloudU = fract(metaU * 128.0) * 0.5;
		vec4 cloud = texture(cloud_atlas, vec2(cloudU, cloudV));
		float contrib = cloud.a * has_cloud * (1.0 - a);
		rgb += cloud.rgb * contrib;
		a   += contrib;
	}
	
    COLOR = vec4(rgb, a);
}