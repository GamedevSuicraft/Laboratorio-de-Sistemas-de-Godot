shader_type sky;

// ============================================================================
// SKY TEXTURE & ROTATION
// ============================================================================
group_uniforms SkyTextureAndRotation;

/** Your main panorama sky texture (automatically darkened and tinted at night). */
uniform sampler2D sky_texture : source_color, filter_linear, hint_default_white;

/** Static horizontal rotation offset in degrees (0 to 360). */
uniform float rotation_offset : hint_range(0.0, 360.0, 0.1) = 0.0;

/** Continuous horizontal rotation speed for the sky panorama (radians per second). */
uniform float rotation_speed : hint_range(-1.0, 1.0, 0.001) = 0.005;

/** Vertical offset to shift the horizon line up or down. */
uniform float vertical_offset : hint_range(-0.5, 0.5, 0.005) = 0.0;


// ============================================================================
// DAY / SUNSET / NIGHT ATMOSPHERE
// ============================================================================
group_uniforms AtmosphereColors;

/** Manual time-of-day override (-1.0 = Midnight, 0.0 = Sunset, 1.0 = Noon). */
uniform bool use_manual_sun_height = false;

/** Manual sun altitude used when use_manual_sun_height is enabled. */
uniform float manual_sun_height : hint_range(-1.0, 1.0, 0.01) = 0.5;

/** Sky brightness multiplier during midday. */
uniform float day_exposure : hint_range(0.1, 5.0, 0.05) = 1.0;

/** Sky brightness multiplier at midnight (darkens your sky_texture at night). */
uniform float night_exposure : hint_range(0.0, 0.5, 0.005) = 0.03;

/** Tint applied to the sky texture during daytime. */
uniform vec3 day_tint : source_color = vec3(1.0, 1.0, 1.0);

/** Tint applied to the sky texture during sunrise and sunset. */
uniform vec3 sunset_tint : source_color = vec3(1.0, 0.45, 0.25);

/** Deep blue/purple tint applied to the darkened sky texture at night. */
uniform vec3 night_tint : source_color = vec3(0.1, 0.2, 0.45);

/** Horizon glow color during the day. */
uniform vec3 day_horizon_color : source_color = vec3(0.45, 0.75, 0.95);

/** Horizon glow color during sunrise and sunset. */
uniform vec3 sunset_horizon_color : source_color = vec3(0.95, 0.35, 0.1);

/** Horizon glow color during the night. */
uniform vec3 night_horizon_color : source_color = vec3(0.02, 0.04, 0.1);

/** Intensity of the horizon haze. */
uniform float horizon_intensity : hint_range(0.0, 2.0, 0.01) = 0.6;

/** Falloff curve of the horizon haze. */
uniform float horizon_falloff : hint_range(0.5, 20.0, 0.1) = 4.5;


// ============================================================================
// SUN & MOON DISCS
// ============================================================================
group_uniforms SunAndMoon;

/** Color of the sun disc. */
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);

/** Angular radius of the sun disc. */
uniform float sun_size : hint_range(0.001, 0.3, 0.001) = 0.035;

/** Halo falloff around the sun. */
uniform float sun_halo_falloff : hint_range(1.0, 200.0, 0.5) = 30.0;

/** Brightness of the sun disc. */
uniform float sun_intensity : hint_range(0.0, 20.0, 0.1) = 3.0;

/** Color of the moon disc. */
uniform vec3 moon_color : source_color = vec3(0.7, 0.85, 1.0);

/** Angular radius of the moon disc. */
uniform float moon_size : hint_range(0.001, 0.3, 0.001) = 0.025;

/** Halo falloff around the moon. */
uniform float moon_halo_falloff : hint_range(1.0, 200.0, 0.5) = 60.0;

/** Brightness of the moon disc. */
uniform float moon_intensity : hint_range(0.0, 10.0, 0.1) = 1.5;


// ============================================================================
// PROCEDURAL STARS (COLOR, SIZE, GLOW & ROTATION)
// ============================================================================
group_uniforms ProceduralStars;

/** Overall brightness multiplier for the night stars (values > 1.5 trigger HDR bloom/glow). */
uniform float star_intensity : hint_range(0.0, 15.0, 0.1) = 2.0;

/** Density threshold for procedural stars (higher = fewer, more subtle stars). */
uniform float star_threshold : hint_range(0.85, 0.999, 0.001) = 0.985;

/** Grid resolution of the starfield (higher = smaller, finer stars). */
uniform float star_grid_scale : hint_range(100.0, 800.0, 10.0) = 380.0;

/** Minimum and maximum radius multiplier for individual stars. */
uniform float star_base_size : hint_range(0.05, 0.45, 0.01) = 0.25;

/** Intensity of the soft outer glow halo around bright stars. */
uniform float star_glow_strength : hint_range(0.0, 3.0, 0.05) = 1.2;

/** Amount of color variation between blue, white, yellow, and red stars (0.0 = pure white, 1.0 = full stellar colors). */
uniform float star_color_variation : hint_range(0.0, 1.0, 0.05) = 0.85;

/** Rotation speed of the star dome across the sky (radians per second). */
uniform float star_rotation_speed : hint_range(-0.2, 0.2, 0.001) = 0.01;

/** Tilt angle (in degrees) of the celestial pole axis around which the stars rotate. */
uniform float star_axis_tilt : hint_range(-90.0, 90.0, 1.0) = 25.0;

/** Speed of the starlight twinkling animation. */
uniform float twinkle_speed : hint_range(0.0, 5.0, 0.05) = 1.2;


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Converts a 3D view direction vector into normalized equirectangular UV coordinates.
 */
vec2 get_spherical_uv(vec3 dir, float rot_rad, float v_offset) {
	float phi = atan(dir.z, dir.x) + rot_rad;
	float theta = acos(clamp(dir.y + v_offset, -1.0, 1.0));
	return vec2(fract(phi / (2.0 * PI) + 0.5), theta / PI);
}

/**
 * Returns a 3D vector hash from a 3D cell coordinate (used for star position jitter, color, and size).
 */
vec3 hash33(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yxz + 19.19);
	return fract((p.xxy + p.yxx) * p.zyx);
}

/**
 * Rotates a 3D direction vector around a tilted celestial axis over time so the starfield revolves naturally.
 */
vec3 rotate_starfield(vec3 dir, float angle, float tilt_deg) {
	// 1. Tilt the coordinate space so the rotation pole is angled
	float tilt_rad = radians(tilt_deg);
	float ct = cos(tilt_rad);
	float st = sin(tilt_rad);
	vec3 tilted = vec3(dir.x, dir.y * ct - dir.z * st, dir.y * st + dir.z * ct);

	// 2. Rotate around the Y axis (celestial pole)
	float ca = cos(angle);
	float sa = sin(angle);
	return vec3(tilted.x * ca + tilted.z * sa, tilted.y, -tilted.x * sa + tilted.z * ca);
}

/**
 * Computes a realistic stellar blackbody color based on a random temperature value in [0.0, 1.0].
 * Includes Red/Orange dwarfs, Yellow sun-like stars, pure White stars, and Blue giants.
 */
vec3 get_stellar_color(float temp_hash, float variation) {
	vec3 col = vec3(1.0);
	if (temp_hash < 0.25) {
		// Red / Orange star (Betelgeuse / Aldebaran style)
		col = mix(vec3(1.0, 0.38, 0.22), vec3(1.0, 0.72, 0.45), temp_hash / 0.25);
	} else if (temp_hash < 0.65) {
		// Warm Yellow to Pure White star
		col = mix(vec3(1.0, 0.72, 0.45), vec3(1.0, 0.98, 1.0), (temp_hash - 0.25) / 0.40);
	} else {
		// White to Bright Blue giant (Rigel / Sirius style)
		col = mix(vec3(1.0, 0.98, 1.0), vec3(0.45, 0.72, 1.0), (temp_hash - 0.65) / 0.35);
	}
	return mix(vec3(1.0), col, variation);
}

/**
 * Computes a celestial disc (sun or moon) and its atmospheric glow halo.
 */
float calculate_celestial_body(vec3 eyedir, vec3 body_dir, float size, float falloff) {
	float cos_angle = dot(eyedir, body_dir);
	float angle_dist = clamp(1.0 - cos_angle, 0.0, 1.0);
	float disc = 1.0 - smoothstep(size * 0.85, size, sqrt(angle_dist * 2.0));
	float halo = pow(clamp(cos_angle, 0.0, 1.0), falloff) * 0.45;
	return clamp(disc + halo, 0.0, 1.0);
}


// ============================================================================
// SKY PROCESSOR
// ============================================================================

void sky() {
	vec3 eyedir = normalize(EYEDIR);

	// 1. Read Sun Direction and Height (-1.0 = Midnight, 0.0 = Horizon, +1.0 = Noon)
	vec3 sun_dir = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : vec3(0.0, 1.0, 0.0);
	float sun_height = use_manual_sun_height ? manual_sun_height : sun_dir.y;
	vec3 moon_dir = -sun_dir;

	// 2. Compute smooth Day, Sunset, and Night weights
	float day_factor = smoothstep(-0.15, 0.25, sun_height);
	float night_factor = 1.0 - day_factor;
	float sunset_factor = smoothstep(-0.25, 0.05, sun_height) * (1.0 - smoothstep(0.05, 0.45, sun_height));

	// 3. Sample Panorama and Darken/Tint for Day, Sunset, and Night
	float total_rotation = radians(rotation_offset) + (TIME * rotation_speed);
	vec2 sky_uv = get_spherical_uv(eyedir, total_rotation, vertical_offset);
	vec3 raw_tex = texture(sky_texture, sky_uv).rgb;

	vec3 current_tint = mix(night_tint, day_tint, day_factor);
	current_tint = mix(current_tint, sunset_tint, sunset_factor);
	float current_exposure = mix(night_exposure, day_exposure, day_factor);

	vec3 final_color = raw_tex * current_tint * current_exposure;

// 4. Smoothly Rotating, Anti-Aliased Procedural Stars (No Sub-Pixel Flickering!)
	if (night_factor > 0.01 && eyedir.y > 0.0 && star_intensity > 0.0) {
		// Rotate the 3D view ray around the tilted celestial axis
		float star_angle = radians(rotation_offset) + (TIME * star_rotation_speed);
		vec3 rot_dir = rotate_starfield(eyedir, star_angle, star_axis_tilt);

		// Convert rotated 3D vector to seamless Spherical UV coordinates so cells never slice across 3D cubes!
		float s_phi = atan(rot_dir.z, rot_dir.x) / (2.0 * PI) + 0.5;
		float s_theta = acos(clamp(rot_dir.y, -1.0, 1.0)) / PI;
		
		// Compensate horizontal stretching near the poles (sin(theta)) so stars stay perfectly round everywhere
		float pole_compensation = max(sin(s_theta * PI), 0.15);
		vec2 star_uv = vec2(s_phi * 2.0 * pole_compensation, s_theta) * star_grid_scale;

		vec2 star_id = floor(star_uv);
		vec2 star_local = fract(star_uv) - 0.5;

		// Generate 3 random values per 2D sky cell
		vec3 rnd = hash33(vec3(star_id, 1.0));

		if (rnd.x > star_threshold) {
			// Keep star away from cell borders to prevent clipping when rotating
			vec2 jitter = (fract(rnd.yz * 17.53) - 0.5) * 0.4;
			float dist = length(star_local - jitter);

			// Rarity factor (0.0 = dim common star, 1.0 = bright rare star)
			float rarity = clamp((rnd.x - star_threshold) / (1.0 - star_threshold), 0.0, 1.0);
			float brightness_curve = pow(rarity, 1.8);

			// Ensure minimum radius is wide enough (>= 0.18) so stars don't flicker between screen pixels while moving
			float current_radius = max(star_base_size * mix(0.65, 1.35, rnd.z) * mix(0.8, 1.2, rarity), 0.18);

			// Soft anti-aliased core + exponential outer glow halo
			float star_core = smoothstep(current_radius * 0.6, current_radius * 0.1, dist);
			float star_halo = smoothstep(current_radius, 0.0, dist);
			star_halo = pow(star_halo, 2.2) * star_glow_strength;
			float star_shape = star_core + star_halo;

			// True Twinkle: strictly equals 1.0 when twinkle_speed is 0.0!
			float twinkle = 1.0;
			if (twinkle_speed > 0.001) {
				float phase = rnd.z * 100.0;
				float speed_var = mix(0.6, 1.4, rnd.y);
				twinkle = 0.65 + 0.35 * sin(TIME * twinkle_speed * speed_var + phase);
			}

			// Stellar color (Red/Orange, Yellow, White, or Blue)
			vec3 star_col = get_stellar_color(rnd.y, star_color_variation);
			vec3 final_star_col = mix(star_col, vec3(1.0), star_core * 0.5);

			float horizon_fade = smoothstep(0.05, 0.35, eyedir.y);
			final_color += final_star_col * star_shape * brightness_curve * twinkle * star_intensity * night_factor * horizon_fade;
		}
	}

	// 5. Render Sun and Moon above the horizon
	if (eyedir.y > -0.05) {
		float sun_vis = smoothstep(-0.1, 0.05, sun_height);
		float sun_disc = calculate_celestial_body(eyedir, sun_dir, sun_size, sun_halo_falloff);
		vec3 current_sun_col = mix(sun_color, sunset_horizon_color, sunset_factor * 0.7);
		final_color += current_sun_col * sun_disc * sun_intensity * sun_vis;

		float moon_vis = smoothstep(-0.1, 0.1, moon_dir.y);
		float moon_disc = calculate_celestial_body(eyedir, moon_dir, moon_size, moon_halo_falloff);
		final_color += moon_color * moon_disc * moon_intensity * moon_vis;
	}

	// 6. Horizon Atmospheric Glow
	vec3 current_horizon = mix(night_horizon_color, day_horizon_color, day_factor);
	current_horizon = mix(current_horizon, sunset_horizon_color, sunset_factor);
	float horizon_mask = pow(1.0 - abs(eyedir.y), horizon_falloff);
	final_color = mix(final_color, current_horizon, clamp(horizon_mask * horizon_intensity, 0.0, 1.0));

	// Darken lower hemisphere below horizon
	if (eyedir.y < 0.0) {
		final_color *= smoothstep(-0.25, 0.0, eyedir.y);
	}

	COLOR = final_color;
}