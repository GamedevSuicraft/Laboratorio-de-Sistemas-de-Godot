shader_type spatial;
// Renders both sides, disables shadows, and blends smoothly over the floor
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

// ============================================================================
// COLOR & EMISSION PARAMETERS
// ============================================================================
group_uniforms ColorsAndEmission;

/** The primary background color of the circular aura interior. */
uniform vec4 base_color : source_color = vec4(0.35, 0.0, 0.75, 0.5);

/** The color applied to the expanding circular shockwave texture. */
uniform vec4 wave_color : source_color = vec4(0.75, 0.3, 1.0, 1.0);

/** The color applied to the outer border ring and chain texture. */
uniform vec4 border_color : source_color = vec4(0.9, 0.5, 1.0, 1.0);

/** Overall HDR glow multiplier (works best with Glow enabled in WorldEnvironment). */
uniform float emission_intensity : hint_range(0.0, 20.0, 0.1) = 3.0;

/** Extra brightness boost triggered via script when minions spawn (0.0 = normal, 1.0 = flash). */
uniform float spawn_flash : hint_range(0.0, 1.0, 0.01) = 0.0;


// ============================================================================
// CIRCLE & CHAIN BORDER PARAMETERS
// ============================================================================
group_uniforms CircleAndBorder;

/** Outer radius of the circular aura in UV space (0.5 fills the plane mesh). */
uniform float outer_radius : hint_range(0.1, 0.5, 0.01) = 0.48;

/** Thickness of the outer border ring where the chain/border texture is drawn. */
uniform float border_width : hint_range(0.01, 0.25, 0.005) = 0.06;

/** Softness of the outer and inner border edges. */
uniform float border_softness : hint_range(0.001, 0.1, 0.001) = 0.015;

/** Optional horizontal tileable texture (e.g., chains, runes, spikes) wrapped around the border ring. */
uniform sampler2D border_texture : hint_default_white, repeat_enable, filter_linear_mipmap;

/** Number of times the chain/border texture repeats around the circumference (X) and across the border thickness (Y). */
uniform vec2 border_texture_tiling = vec2(12.0, 1.0);

/** Scrolling speed of the chain/border texture around the circle (positive = clockwise, negative = counter-clockwise). */
uniform float border_scroll_speed : hint_range(-5.0, 5.0, 0.05) = 0.5;

/** Blends between a solid glowing border (0.0) and the cutout chain/border texture (1.0). */
uniform float border_texture_strength : hint_range(0.0, 1.0, 0.05) = 1.0;


// ============================================================================
// EXPANDING RING TEXTURE PARAMETERS (CENTER TO OUTWARD)
// ============================================================================
group_uniforms ExpandingWaveTexture;

/** Your centered circular black-and-white ring texture that expands from the player outward. */
uniform sampler2D wave_texture : hint_default_black, repeat_disable, filter_linear_mipmap;

/** Speed at which the ring texture expands from the center (0.0) to the outer border (1.0). */
uniform float expansion_speed : hint_range(0.05, 3.0, 0.05) = 0.5;

/** Rotation speed (radians/sec) of the expanding ring texture as it grows. */
uniform float wave_rotation_speed : hint_range(-3.0, 3.0, 0.05) = 0.2;

/** Minimum scale at the start of the expansion (smaller = starts tighter around the player's feet). */
uniform float min_wave_scale : hint_range(0.05, 1.0, 0.05) = 0.15;

/** Maximum scale at the end of the expansion (larger = expands all the way past the border). */
uniform float max_wave_scale : hint_range(0.5, 3.0, 0.05) = 1.35;

/** Spawns a second overlapping wave offset by half a cycle for a continuous, uninterrupted pulsing effect. */
uniform bool enable_dual_wave = true;

/** Intensity multiplier for the expanding wave texture. */
uniform float wave_intensity : hint_range(0.0, 5.0, 0.05) = 1.8;


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Rotates centered 2D coordinates around the origin (0, 0) by a given angle in radians.
 *
 * @param centered_uv UV coordinates already shifted by -0.5 so (0,0) is the center.
 * @param angle Rotation angle in radians.
 * @return Rotated 2D coordinates.
 */
vec2 rotate_uv(vec2 centered_uv, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	return vec2(centered_uv.x * c - centered_uv.y * s, centered_uv.x * s + centered_uv.y * c);
}

/**
 * Samples the centered circular wave texture at a specific life phase [0.0 -> 1.0],
 * scaling it outward from the center and fading it smoothly at birth (0.0) and death (1.0).
 *
 * @param centered_uv Planar UV coordinates centered at (0, 0).
 * @param phase Normalized expansion progress from 0.0 (center) to 1.0 (outer edge).
 * @param rot_angle Rotation angle in radians.
 * @return Brightness value of the expanding wave at the current pixel.
 */
float sample_expanding_ring(vec2 centered_uv, float phase, float rot_angle) {
	// Interpolate scale from small (center) to large (outer edge)
	float current_scale = mix(min_wave_scale, max_wave_scale, phase);
	
	// Divide centered UVs by current_scale so the texture grows outward as current_scale increases
	vec2 scaled_uv = rotate_uv(centered_uv, rot_angle) / max(current_scale, 0.001) + vec2(0.5);
	
	// Ensure we don't sample outside the [0..1] texture bounds
	if (scaled_uv.x < 0.0 || scaled_uv.x > 1.0 || scaled_uv.y < 0.0 || scaled_uv.y > 1.0) {
		return 0.0;
	}
	
	float tex_val = texture(wave_texture, scaled_uv).r;
	
	// Smoothly fade in at the center (0.0 -> 0.15) and fade out as it reaches the border (0.7 -> 1.0)
	float fade_envelope = smoothstep(0.0, 0.15, phase) * (1.0 - smoothstep(0.65, 1.0, phase));
	return tex_val * fade_envelope;
}


// ============================================================================
// FRAGMENT PROCESSOR
// ============================================================================

/**
 * Fragment processor: combines a circular base aura, dual outward-scaling shockwave rings,
 * and a polar-mapped scrolling chain texture along the outer border.
 */
void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);

	// 1. Discard pixels outside the circular aura
	if (dist > outer_radius) {
		discard;
	}

	// 2. Compute Base Circle Mask
	float circle_mask = 1.0 - smoothstep(outer_radius - border_softness, outer_radius, dist);

	// 3. Compute Expanding Ring Waves (Planar Center-Outward Scaling)
	float phase1 = fract(TIME * expansion_speed);
	float rot1 = TIME * wave_rotation_speed;
	float wave_val = sample_expanding_ring(centered_uv, phase1, rot1);

	if (enable_dual_wave) {
		// Second wave offset by 0.5 (half cycle) and rotated by 45 degrees for variety
		float phase2 = fract(TIME * expansion_speed + 0.5);
		float rot2 = -TIME * wave_rotation_speed + 0.785;
		wave_val = max(wave_val, sample_expanding_ring(centered_uv, phase2, rot2));
	}

	// Mask out the wave outside the inner border edge so it doesn't bleed past the chains
	float inner_border_radius = outer_radius - border_width;
	float wave_radial_clip = 1.0 - smoothstep(inner_border_radius, outer_radius, dist);
	float final_wave_mask = clamp(wave_val * wave_intensity * wave_radial_clip, 0.0, 1.0);

	// 4. Compute Outer Border Ring & Polar-Mapped Chain Texture
	float outer_edge = 1.0 - smoothstep(outer_radius - border_softness, outer_radius, dist);
	float inner_edge = smoothstep(inner_border_radius - border_softness, inner_border_radius, dist);
	float border_ring_mask = clamp(outer_edge * inner_edge, 0.0, 1.0);

	// Map polar coordinates strictly to the border strip so a horizontal chain texture wraps around the circle!
	float angle_01 = atan(centered_uv.y, centered_uv.x) / (2.0 * PI) + 0.5;
	float border_v = clamp((dist - inner_border_radius) / max(border_width, 0.001), 0.0, 1.0);
	vec2 chain_uv = vec2(
		fract(angle_01 * border_texture_tiling.x + (TIME * border_scroll_speed)),
		border_v * border_texture_tiling.y
	);

	// Support both black-and-white masks (.r) and transparent PNGs (.a) for the chain texture
	vec4 border_tex_sample = texture(border_texture, chain_uv);
	float chain_pattern = border_tex_sample.r * border_tex_sample.a;
	float final_border_mask = border_ring_mask * mix(1.0, chain_pattern, border_texture_strength);

	// 5. Combine Colors (Base -> Expanding Wave -> Border Chains -> Spawn Flash)
	vec3 final_rgb = base_color.rgb;
	final_rgb = mix(final_rgb, wave_color.rgb, final_wave_mask);
	final_rgb = mix(final_rgb, border_color.rgb, final_border_mask);
	final_rgb = mix(final_rgb, vec3(1.0), spawn_flash * 0.65);

	// 6. Compute Final Opacity (Alpha)
	float base_a = base_color.a * circle_mask;
	float wave_a = final_wave_mask * wave_color.a * circle_mask;
	float border_a = final_border_mask * border_color.a;
	float final_alpha = clamp(max(base_a, max(wave_a, border_a)) + (spawn_flash * 0.3 * circle_mask), 0.0, 1.0);

	ALBEDO = final_rgb;
	EMISSION = final_rgb * (emission_intensity + (spawn_flash * 6.0));
	ALPHA = final_alpha;
}