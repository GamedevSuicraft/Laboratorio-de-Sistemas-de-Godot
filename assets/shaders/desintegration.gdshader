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
 * - Uniform (0): Dissolves randomly across the entire mesh using pure noise.
 * - Bottom to Top (1): Sweeps upward along the vertical texture coordinate (UV.y inverted).
 * - Top to Bottom (2): Sweeps downward along the vertical texture coordinate (UV.y).
 * - UV Horizontal Start to End (3): Sweeps across the horizontal UV seam/projection (UV.x).
 * - UV Horizontal End to Start (4): Sweeps in reverse across the horizontal UV seam/projection (1.0 - UV.x).
 * Note: Directional modes rely on the mesh's UV unwrapping/projection layout.
 */
uniform int dissolve_mode : hint_enum("Uniform:0", "Bottom to Top (UV.y):1", "Top to Bottom (UV.y):2", "UV Horizontal (U -> 1):3", "UV Horizontal (1 -> U):4") = 0;

/**
 * Grayscale noise texture used to break up the disintegration surface.
 */
uniform sampler2D noise_texture : repeat_enable, filter_linear;

/**
 * Scaling factor for the noise pattern across world coordinates.
 */
uniform float noise_scale : hint_range(0.5, 3.0) = 1.0;

/**
 * Width of the glowing burn edge.
 */
uniform float edge_width : hint_range(0.0, 0.5) = 0.06;

/**
 * Color of the glowing burn edge.
 */
uniform vec4 edge_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

/**
 * Multiplier for edge emission brightness.
 */
uniform float emission_energy : hint_range(0.0, 100.0) = 12.0;

/**
 * Base surface color.
 */
uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // 1. Sample world-space noise for organic breakup
    float noise_val = texture(noise_texture, world_position.xz * noise_scale).r;

    // 2. Compute directional wave along the mesh UV coordinates
    float dir_val = 0.0;
    
    if (dissolve_mode == 1) {
        // Vertical sweep: bottom to top
        dir_val = 1.0 - UV.y;
    } else if (dissolve_mode == 2) {
        // Vertical sweep: top to bottom
        dir_val = UV.y;
    } else if (dissolve_mode == 3) {
        // Horizontal sweep along UV seam
        dir_val = UV.x;
    } else if (dissolve_mode == 4) {
        // Reverse horizontal sweep along UV seam
        dir_val = 1.0 - UV.x;
    }

    // 3. Blend direction gradient with noise breakup
    float cutoff = noise_val;
    if (dissolve_mode > 0) {
        cutoff = clamp(dir_val * 0.75 + noise_val * 0.25, 0.0, 1.0);
    }

    // 4. Safe threshold range ensuring total visibility at 0.0 and total discard at 1.0
    float threshold = mix(-edge_width - 0.01, 1.0 + edge_width + 0.01, dissolve_amount);

    if (cutoff < threshold) {
        discard;
    }

    ALBEDO = albedo.rgb;

    // 5. Emissive burn edge
    if (cutoff < threshold + edge_width && dissolve_amount > 0.0 && dissolve_amount < 1.0) {
        float edge_intensity = 1.0 - smoothstep(threshold, threshold + edge_width, cutoff);
        EMISSION = edge_color.rgb * emission_energy * edge_intensity;
    } else {
        EMISSION = vec3(0.0);
    }
}