shader_type spatial;
// Renders both sides of the mesh, disables shadows, and uses additive/alpha blending
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

// ============================================================================
// COLOR & EMISSION PARAMETERS
// ============================================================================
group_uniforms ColorAndEmission;

/** The primary base color of the force field interior. */
uniform vec4 base_color : source_color = vec4(0.0, 0.4, 0.9, 0.15);

/** The glowing color applied to edges, intersections, and pattern highlights. */
uniform vec4 edge_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);

/** Multiplier for the overall emission brightness (works best with Glow enabled in WorldEnvironment). */
uniform float emission_intensity : hint_range(0.0, 20.0, 0.1) = 4.0;


// ============================================================================
// EDGE & INTERSECTION PARAMETERS (FRESNEL & DEPTH)
// ============================================================================
group_uniforms EdgeAndIntersection;

/** Controls the width and falloff of the outer silhouette glow (Fresnel effect). Lower values create a wider border. */
uniform float fresnel_power : hint_range(0.1, 15.0, 0.1) = 3.0;

/** Controls the thickness of the glowing border where the force field intersects with other 3D objects or the ground. */
uniform float intersection_width : hint_range(0.0, 5.0, 0.01) = 0.6;

/** Controls the softness/curve of the intersection glow transition. */
uniform float intersection_softness : hint_range(0.1, 10.0, 0.1) = 2.0;

/** Built-in depth texture required to calculate geometry intersections in Godot 4. */
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;


// ============================================================================
// PATTERN & ANIMATION PARAMETERS
// ============================================================================
group_uniforms PatternAndMovement;

/** The main pattern texture (e.g., hexagonal grid, scanlines, or energy waves). */
uniform sampler2D pattern_texture : source_color, hint_default_black, repeat_enable, filter_linear_mipmap;

/** UV tiling scale for the pattern texture. */
uniform vec2 pattern_scale = vec2(6.0, 6.0);

/** Scrolling speed (X, Y) for the pattern texture animation. */
uniform vec2 pattern_scroll_speed = vec2(0.0, -0.15);

/** Controls how strongly the pattern contributes to the emission and opacity. */
uniform float pattern_intensity : hint_range(0.0, 5.0, 0.05) = 1.5;


// ============================================================================
// DISTORTION & NOISE PARAMETERS
// ============================================================================
group_uniforms DistortionAndNoise;

/** Noise texture used to warp the pattern UVs and drive the dissolve effect. */
uniform sampler2D noise_texture : hint_default_white, repeat_enable, filter_linear_mipmap;

/** UV tiling scale for the noise texture. */
uniform vec2 noise_scale = vec2(2.0, 2.0);

/** Scrolling speed (X, Y) for the noise distortion animation. */
uniform vec2 noise_scroll_speed = vec2(0.1, 0.1);

/** Intensity of the UV warping applied to the pattern texture to create a liquid/plasma movement. */
uniform float distortion_strength : hint_range(0.0, 0.5, 0.005) = 0.03;


// ============================================================================
// DISSOLVE & PULSE PARAMETERS
// ============================================================================
group_uniforms DissolveAndPulse;

/** Dissolves the force field based on the noise texture (0.0 = fully intact, 1.0 = fully dissolved). */
uniform float dissolve_amount : hint_range(0.0, 1.0, 0.01) = 0.0;

/** Width of the glowing edge around dissolved holes. */
uniform float dissolve_edge_width : hint_range(0.0, 0.3, 0.005) = 0.06;

/** Color of the burning edge around dissolved areas. */
uniform vec4 dissolve_edge_color : source_color = vec4(0.8, 0.3, 1.0, 1.0);

/** Speed of the vertex breathing/pulsing animation. */
uniform float pulse_speed : hint_range(0.0, 10.0, 0.1) = 2.0;

/** Amplitude (distance) of the vertex displacement along the surface normals. */
uniform float pulse_amplitude : hint_range(0.0, 0.5, 0.005) = 0.01;

/** Frequency of the wave travelling across the mesh surface during pulsing. */
uniform float pulse_frequency : hint_range(0.0, 20.0, 0.1) = 4.0;


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Calculates the Fresnel effect to highlight the silhouette edges of the mesh.
 *
 * @param normal The surface normal vector in view space.
 * @param view The normalized view vector pointing towards the camera.
 * @param power The exponent controlling the sharpness and width of the rim glow.
 * @return A float between 0.0 and 1.0 representing the Fresnel rim intensity.
 */
float calculate_fresnel(vec3 normal, vec3 view, float power) {
	// abs() ensures correct calculation even when rendering back-faces (cull_disabled)
	float dot_product = clamp(abs(dot(normalize(normal), normalize(view))), 0.0, 1.0);
	return pow(1.0 - dot_product, power);
}

/**
 * Converts a non-linear depth sample from the depth buffer into linear view-space depth.
 *
 * @param depth_tex The depth buffer sampler.
 * @param screen_uv The normalized screen coordinates of the current fragment.
 * @param inv_proj_matrix The inverse projection matrix (INV_PROJECTION_MATRIX).
 * @return The linear distance from the camera to the background geometry.
 */
float get_linear_depth(sampler2D depth_tex, vec2 screen_uv, mat4 inv_proj_matrix) {
	float raw_depth = texture(depth_tex, screen_uv).r;
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
	vec4 view_pos = inv_proj_matrix * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	return -view_pos.z;
}

/**
 * Calculates the intersection glow factor where the mesh overlaps scene geometry.
 *
 * @param scene_depth Linear depth of the opaque geometry behind the fragment.
 * @param fragment_depth Linear depth of the current force field fragment.
 * @param width Maximum distance threshold for the intersection highlight.
 * @param softness Exponent curve to smooth out the intersection transition.
 * @return A float between 0.0 and 1.0 representing the intersection glow intensity.
 */
float calculate_intersection(float scene_depth, float fragment_depth, float width, float softness) {
	if (width <= 0.0001) {
		return 0.0;
	}
	float depth_diff = scene_depth - fragment_depth;
	float intersection = clamp(1.0 - (depth_diff / width), 0.0, 1.0);
	return pow(intersection, softness);
}


// ============================================================================
// SHADER STAGES
// ============================================================================

/**
 * Vertex processor: applies a sinusoidal wave displacement along vertex normals
 * to give the force field a subtle, organic breathing motion.
 */
void vertex() {
	if (pulse_amplitude > 0.0) {
		float wave = sin(TIME * pulse_speed + VERTEX.y * pulse_frequency) * pulse_amplitude;
		VERTEX += NORMAL * wave;
	}
}

/**
 * Fragment processor: combines Fresnel rim lighting, depth intersection,
 * UV-distorted scrolling patterns, and noise-driven dissolve into the final material.
 */
void fragment() {
	// 1. Sample animated noise for distortion and dissolve
	vec2 animated_noise_uv = UV * noise_scale + (TIME * noise_scroll_speed);
	float noise_value = texture(noise_texture, animated_noise_uv).r;

	// 2. Process Dissolve Effect
	float dissolve_mask = 1.0;
	float dissolve_rim = 0.0;
	if (dissolve_amount > 0.0) {
		// Remap threshold slightly so 0.0 is completely intact and 1.0 is completely gone
		float threshold = dissolve_amount * (1.0 + dissolve_edge_width);
		if (noise_value < threshold - dissolve_edge_width) {
			discard;
		}
		// Calculate the glowing edge around dissolved holes
		dissolve_rim = 1.0 - smoothstep(threshold - dissolve_edge_width, threshold, noise_value);
	}

	// 3. Sample animated & distorted pattern texture
	vec2 distortion_offset = (vec2(noise_value) - 0.5) * 2.0 * distortion_strength;
	vec2 animated_pattern_uv = (UV * pattern_scale) + (TIME * pattern_scroll_speed) + distortion_offset;
	vec4 pattern_sample = texture(pattern_texture, animated_pattern_uv);
	float pattern_mask = pattern_sample.r * pattern_intensity;

	// 4. Calculate Fresnel (Outer Rim Glow)
	float fresnel = calculate_fresnel(NORMAL, VIEW, fresnel_power);

	// 5. Calculate Depth Intersection (Contact Glow with Ground/Objects)
	float scene_depth = get_linear_depth(depth_texture, SCREEN_UV, INV_PROJECTION_MATRIX);
	float current_depth = -VERTEX.z;
	float intersection = calculate_intersection(scene_depth, current_depth, intersection_width, intersection_softness);

	// 6. Combine Edge Masks (Fresnel + Intersection + Pattern)
	float combined_edge = max(fresnel, intersection);
	float total_highlight = clamp(combined_edge + (pattern_mask * (0.3 + 0.7 * combined_edge)), 0.0, 1.0);

	// 7. Compute Final Color and Emission
	vec3 final_color = mix(base_color.rgb, edge_color.rgb, total_highlight);
	// Add pattern direct contribution
	final_color += edge_color.rgb * pattern_mask * 0.5;
	// Apply dissolve burning border
	final_color = mix(final_color, dissolve_edge_color.rgb, dissolve_rim);

	// 8. Compute Final Opacity (Alpha)
	float base_alpha = base_color.a;
	float highlight_alpha = clamp(combined_edge + (pattern_mask * 0.6) + dissolve_rim, 0.0, 1.0) * edge_color.a;
	float final_alpha = clamp( base_alpha + highlight_alpha, 0.0, 1.0 );

	ALBEDO = final_color;
	EMISSION = final_color * emission_intensity;
	ALPHA = final_alpha;
}