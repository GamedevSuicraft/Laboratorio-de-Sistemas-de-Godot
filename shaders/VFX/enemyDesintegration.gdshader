shader_type spatial;
render_mode cull_disabled;

/**
 * Disintegration progress.
 * 0.0 = completely solid and intact.
 * 1.0 = guaranteed fully dissolved.
 */
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;

/**
 * Disintegration pattern style:
 * - Uniform (0): Dissolves randomly across the entire mesh using noise.
 * - Bottom to Top (1): Sweeps upward through the character's height.
 * - Top to Bottom (2): Sweeps downward from head to feet.
 */
uniform int dissolve_mode : hint_enum("Uniform:0", "Bottom to Top:1", "Top to Bottom:2") = 0;

/**
 * Height span of the enemy (approx. distance from feet to head in meters).
 */
uniform float character_height : hint_range(0.5, 10.0) = 2.0;

/**
 * Original character textures.
 */
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform vec4 albedo_tint : source_color = vec4(1.0);

/**
 * Grayscale noise texture.
 */
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform float noise_scale : hint_range(0.5, 3.0) = 1.0;

/**
 * Edge emission settings.
 */
uniform float edge_width : hint_range(0.0, 0.5) = 0.06;
uniform vec4 edge_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float emission_energy : hint_range(0.0, 100.0) = 12.0;

varying vec3 local_vertex;
varying vec3 world_position;

void vertex() {
    local_vertex = VERTEX;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // 1. Maintain the enemy's original texture
    vec4 base_color = texture(texture_albedo, UV) * albedo_tint;

    // 2. Sample noise in world coordinates to prevent stretching during animations
    float noise_val = texture(noise_texture, world_position.xz * noise_scale).r;

    // 3. Normalized height calculation across the whole character body
    // Maps vertex Y position into a clean 0.0 -> 1.0 range
    float height_gradient = clamp((local_vertex.y / character_height) + 0.5, 0.0, 1.0);

    float dir_val = 0.0;
    if (dissolve_mode == 1) {
        dir_val = height_gradient;       // Bottom to top
    } else if (dissolve_mode == 2) {
        dir_val = 1.0 - height_gradient; // Top to bottom
    }

    // 4. Combine noise and wave
    float cutoff = noise_val;
    if (dissolve_mode > 0) {
        cutoff = clamp(dir_val * 0.7 + noise_val * 0.3, 0.0, 1.0);
    }

    // 5. Threshold with safety margins
    float threshold = mix(-edge_width - 0.01, 1.0 + edge_width + 0.01, dissolve_amount);
    if (cutoff < threshold) {
        discard;
    }

    ALBEDO = base_color.rgb;

    // 6. Glowing burn edge
    if (cutoff < threshold + edge_width && dissolve_amount > 0.0 && dissolve_amount < 1.0) {
        float edge_intensity = 1.0 - smoothstep(threshold, threshold + edge_width, cutoff);
        EMISSION = edge_color.rgb * emission_energy * edge_intensity;
    } else {
        EMISSION = vec3(0.0);
    }
}