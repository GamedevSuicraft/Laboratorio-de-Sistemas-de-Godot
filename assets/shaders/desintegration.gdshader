shader_type spatial;
render_mode cull_disabled;

/**
 * Controls the overall progress of the disintegration effect.
 * 0.0 = completely intact, 1.0 = fully dissolved.
 */
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;

/**
 * Grayscale noise texture used to determine the dissolve pattern.
 */
uniform sampler2D noise_texture : repeat_enable, filter_linear;

/**
 * Width of the glowing burn edge.
 */
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;

/**
 * Base color of the burn/ember edge.
 */
uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.0, 1.0);

/**
 * Multiplier for the edge emission/glow strength.
 */
uniform float emission_energy : hint_range(1.0, 100.0) = 3.0;

/**
 * Albedo color/texture for the polygon surface.
 */
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;

void fragment() {
    vec4 base_color = texture(albedo_texture, UV) * albedo;
    float noise_val = texture(noise_texture, UV).r;
    
    // Discard fragments below threshold
    if (noise_val < dissolve_amount) {
        discard;
    }
    
    ALBEDO = base_color.rgb;
    
    // Glowing edge emission
    if (noise_val < dissolve_amount + edge_width && dissolve_amount > 0.0) {
        float edge_intensity = 1.0 - smoothstep(dissolve_amount, dissolve_amount + edge_width, noise_val);
        EMISSION = edge_color.rgb * emission_energy * edge_intensity;
    } else {
        EMISSION = vec3(0.0);
    }
}