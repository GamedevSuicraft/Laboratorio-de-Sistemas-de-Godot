shader_type spatial;
// unshaded: ignores scene lighting; HDR values in ALBEDO directly trigger Glow
// cull_disabled: renders both front and back faces so it looks great from any angle
// blend_add: additive blending for energy effects
// depth_draw_never: prevents front faces from occluding back faces of the same transparent cylinder
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

group_uniforms Color_And_Emission;
/**
 * Base color and overall opacity of the spiral effect.
 */
uniform vec4 albedo_color : source_color = vec4(0.2, 1.0, 0.5, 1.0);

/**
 * Brightness multiplier. Drives ALBEDO into HDR values (> 1.0) to trigger WorldEnvironment Glow.
 */
uniform float emission_energy : hint_range(0.0, 100.0, 0.1) = 3.0;

/**
 * Texture applied to the spiral trail. MUST be a seamless/tileable texture.
 * Note: texture_scale.x is automatically rounded to an integer so it never creates a seam.
 */
uniform sampler2D effect_texture : source_color, hint_default_white, repeat_enable;

/**
 * Tiling/scale of the effect texture. X controls tiling along the spiral circumference; Y controls vertical tiling.
 */
uniform vec2 texture_scale = vec2(1.0, 1.0);


group_uniforms Geometry_Masking;
/**
 * Threshold based on the vertex vertical normal to automatically discard top and bottom caps.
 */
uniform float cap_cutoff_threshold : hint_range(0.5, 0.99, 0.01) = 0.85;

/**
 * Enable this if you are using Godot's built-in CylinderMesh with Cap Top or Cap Bottom enabled.
 */
uniform bool remap_godot_cylinder_uv = true;


group_uniforms Spiral_Geometry;
/**
 * Number of simultaneous spiral bands wrapping around the cylinder or cone.
 * Automatically rounded to whole integers in the shader to guarantee a 100% seamless wrap.
 */
uniform int strand_count : hint_range(1, 20, 1) = 3;

/**
 * Controls how tightly the spiral twists around the mesh from bottom to top.
 * Positive values twist clockwise; negative values twist counter-clockwise.
 */
uniform float spiral_twist : hint_range(-10.0, 10.0, 0.1) = 3.0;

/**
 * Thickness of each spiral band relative to the spacing between bands.
 */
uniform float strand_thickness : hint_range(0.01, 1.0, 0.01) = 0.35;

/**
 * Softens the lateral edges of each spiral band. Higher values create a smoother gradient.
 */
uniform float strand_softness : hint_range(0.01, 0.5, 0.01) = 0.15;


group_uniforms Trail_And_Animation;
/**
 * Speed and direction of the vertical movement. 
 * Positive values make the spiral rise; negative values make it descend.
 */
uniform float vertical_speed : hint_range(-10.0, 10.0, 0.05) = 1.0;

/**
 * Speed of the horizontal rotation around the central axis of the mesh.
 */
uniform float rotation_speed : hint_range(-10.0, 10.0, 0.05) = 0.5;

/**
 * Number of pulses/trails per full spiral revolution.
 * Uses integer steps so the head/tail fade never breaks across the cylinder's circumference.
 */
uniform int pulses_per_turn : hint_range(1, 10, 1) = 1;

/**
 * Length of the visible trail along the spiral path (1.0 = continuous ribbon, lower = shorter pulses).
 */
uniform float trail_length : hint_range(0.05, 1.0, 0.01) = 1.0;

/**
 * Controls how smoothly the tail of the pulse fades out behind the leading edge.
 */
uniform float trail_fade : hint_range(0.01, 1.0, 0.01) = 0.3;


group_uniforms End_And_Border_Opacity;
/**
 * Normalized position along the cylinder (0.0 = start, 1.0 = end) where the effect begins 
 * fading towards 'end_opacity'.
 */
uniform float end_fade_start : hint_range(0.0, 1.0, 0.01) = 0.5;

/**
 * Target opacity multiplier when the effect reaches the end of the cylinder (0.0 = invisible, 1.0 = full opacity).
 */
uniform float end_opacity : hint_range(0.0, 1.0, 0.01) = 0.0;

/**
 * Invert which end of the cylinder is considered the destination for the fade out.
 */
uniform bool invert_end_fade_direction = false;

/**
 * Softly fades both the very bottom and very top edges of the lateral mesh to prevent sharp geometry cuts.
 */
uniform float border_softness : hint_range(0.0, 0.3, 0.01) = 0.08;

/**
 * Softens the lateral silhouette edges when viewing the cylinder from the side (Grazing angle fade).
 * Set to 0.0 to keep full intensity at the extreme left/right edges of the cylinder.
 */
uniform float silhouette_softness : hint_range(0.0, 2.0, 0.05) = 0.2;

// Varyings to compute seamless cylindrical coordinates in fragment shader
varying float v_local_normal_y;
varying vec3 v_local_pos;

void vertex() {
	v_local_normal_y = abs(NORMAL.y);
	v_local_pos = VERTEX;
}

void fragment() {
	// 1. Discard top and bottom caps completely based on local surface normal
	if (v_local_normal_y > cap_cutoff_threshold) {
		discard;
	}
	
	// 2. Compute a 100% seamless radial angle [0.0, 1.0] directly from 3D local position
	// Calculating atan() in fragment avoids mesh UV seams and vertex interpolation artifacts
	float radial_u = (atan(v_local_pos.x, v_local_pos.z) / TAU) + 0.5;
	
	// 3. Normalize vertical coordinate so 0.0 is bottom and 1.0 is top
	float raw_v = remap_godot_cylinder_uv ? clamp(UV.y * 2.0, 0.0, 1.0) : UV.y;
	float y_coord = 1.0 - raw_v;
	
	// 4. Calculate animated time offsets
	float time_vertical = TIME * vertical_speed;
	float time_rotational = TIME * rotation_speed;
	float strands = float(strand_count);
	
	// 5. Compute seamless spiral phase
	// Because 'strands' is strictly an integer, radial_u * strands wraps around 0.0 -> 1.0 without any seam!
	float spiral_phase = (radial_u * strands) + (y_coord * spiral_twist) - time_rotational - time_vertical;
	float strand_uv = fract(spiral_phase);
	float dist_from_strand_center = abs(strand_uv - 0.5) * 2.0;
	
	// Radial mask for the spiral bands
	float strand_mask = 1.0 - smoothstep(
		max(0.0, strand_thickness - strand_softness), 
		min(1.0, strand_thickness + strand_softness), 
		dist_from_strand_center
	);
	
	// 6. Seamless Longitudinal Trail Mask
	// By driving the pulse using radial_u multiplied by an integer (pulses_per_turn),
	// the trail wraps seamlessly around the 360-degree cylinder without vertical cuts.
	float trail_mask = 1.0;
	if (trail_length < 0.999) {
		float pulse_phase = fract((radial_u * float(pulses_per_turn)) - (y_coord * spiral_twist * 0.25) - time_vertical - time_rotational);
		float trail_head = smoothstep(0.0, 0.08, pulse_phase);
		float trail_tail = 1.0 - smoothstep(
			max(0.0, trail_length - trail_fade), 
			trail_length, 
			pulse_phase
		);
		trail_mask = trail_head * trail_tail;
	}
	
	// 7. Sample the effect texture seamlessly
	// Rounding texture_scale.x to the nearest integer ensures the texture tiles seamlessly around the cylinder
	float seamless_tex_scale_x = max(1.0, round(texture_scale.x));
	vec2 aligned_uv = vec2(
		radial_u * seamless_tex_scale_x - time_rotational, 
		(y_coord * texture_scale.y) - time_vertical
	);
	vec4 tex_color = texture(effect_texture, aligned_uv);
	
	// 8. Calculate End Opacity (fading as the effect reaches the destination end of the cylinder)
	bool rising = (vertical_speed >= 0.0);
	if (invert_end_fade_direction) {
		rising = !rising;
	}
	float travel_progress = rising ? y_coord : (1.0 - y_coord);
	float end_fade_factor = smoothstep(end_fade_start, 1.0, travel_progress);
	float current_end_opacity = mix(1.0, end_opacity, end_fade_factor);
	
	// 9. Soften the extreme top and bottom borders
	float border_fade = 1.0;
	if (border_softness > 0.0) {
		border_fade = smoothstep(0.0, border_softness, y_coord) * 
		              smoothstep(0.0, border_softness, 1.0 - y_coord);
	}
	
	// 10. Optional Fresnel/Silhouette softening so the outer edges of the cylinder don't look overly harsh
	float fresnel_fade = 1.0;
	if (silhouette_softness > 0.0) {
		float view_dot = abs(dot(NORMAL, VIEW));
		fresnel_fade = pow(clamp(view_dot, 0.0, 1.0), silhouette_softness);
	}
	
	// 11. Combine color, HDR emission, and all opacity masks
	vec3 base_rgb = albedo_color.rgb * tex_color.rgb;
	float final_alpha = albedo_color.a * tex_color.r * tex_color.a * strand_mask * trail_mask * current_end_opacity * border_fade * fresnel_fade;
	
	ALBEDO = base_rgb * (1.0 + emission_energy);
	ALPHA = clamp(final_alpha, 0.0, 1.0);
}