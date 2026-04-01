shader_type canvas_item;

// The sky is a ligher color down the bottom, very light in the middle, and darker at the top.
uniform vec4 sky_top: source_color = vec4(0.1, 0.2, 0.5, 1.0);
uniform vec4 sky_mid: source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform vec4 sky_bottom: source_color = vec4(0.3, 0.5, 0.9, 1.0);
// The y value of the horizon line, where the sky transitions from light to dark. 
uniform float horizon: hint_range(0.0, 1.0) = 0.5;
// The range over which to blend the horizon line, to avoid a hard edge.
uniform float horizon_blend: hint_range(0.0, 0.5) = 0.25;

void fragment() {
	// use smoothstep to create a smooth gradient between the sky colors based on the UV.y value
    float t_top = smoothstep(0.0, horizon, UV.y);
    float t_bot = smoothstep(horizon, 1.0, UV.y);
    vec4 upper = mix(sky_top, sky_mid, t_top);
    vec4 lower = mix(sky_mid, sky_bottom, t_bot);
    float in_lower = smoothstep(horizon - horizon_blend, horizon + horizon_blend, UV.y);
    COLOR = mix(upper, lower, in_lower);
}