shader_type canvas_item;

/**
 * Access the rendered screen behind this ColorRect.
 */
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// ==========================================
// 1. GENERAL SETTINGS
// ==========================================
group_uniforms General;

/**
 * Master intensity multiplier for the chromatic displacement.
 */
uniform float strength : hint_range(0.0, 0.05) = 0.008;

/**
 * Base direction angle in degrees (0 = horizontal, 90 = vertical).
 */
uniform float angle_degrees : hint_range(0.0, 360.0) = 0.0;

// ==========================================
// 2. CHANNEL OFFSETS (RGB)
// ==========================================
group_uniforms Channels;

/**
 * Multiplier along the angle vector for the Red channel.
 * Default: 1.0 (shifts forward).
 */
uniform float red_shift : hint_range(-2.0, 2.0) = 1.0;

/**
 * Multiplier along the angle vector for the Green channel.
 * Default: 0.0 (stays centered).
 */
uniform float green_shift : hint_range(-2.0, 2.0) = 0.0;

/**
 * Multiplier along the angle vector for the Blue channel.
 * Default: -1.0 (shifts in the opposite direction).
 */
uniform float blue_shift : hint_range(-2.0, 2.0) = -1.0;

// ==========================================
// 3. ANIMATION & PULSE
// ==========================================
group_uniforms Animation;

/**
 * Oscillation speed over time. Set to 0.0 to keep it static.
 */
uniform float pulse_speed : hint_range(0.0, 20.0) = 0.0;

/**
 * Minimum baseline strength during the pulse wave (0.0 = fades to zero, 1.0 = constant).
 */
uniform float pulse_depth : hint_range(0.0, 1.0) = 0.5;

// ==========================================
// 4. MASKING & BORDER FALLOFF
// ==========================================
group_uniforms Mask;

/**
 * Controls whether the effect applies uniformly or as a border mask.
 * 0 = Full screen uniform.
 * 1 = Radial Border (protects screen center, intensifies at edges).
 */
uniform int mask_mode : hint_enum("Full Screen:0", "Radial Border:1") = 0;

/**
 * Curve falloff when using Radial Border mask mode.
 */
uniform float mask_falloff : hint_range(0.5, 4.0) = 2.0;

// ==========================================
// SHADER LOGIC
// ==========================================
group_uniforms; // Resets grouping

void fragment() {
    // 1. Compute unit vector from angle
    float rad = radians(angle_degrees);
    vec2 dir = vec2(cos(rad), sin(rad));

    // 2. Compute dynamic pulse wave
    float pulse = 1.0;
    if (pulse_speed > 0.0) {
        float wave = sin(TIME * pulse_speed) * 0.5 + 0.5;
        pulse = mix(1.0 - pulse_depth, 1.0, wave);
    }

    // 3. Optional edge mask
    float mask = 1.0;
    if (mask_mode == 1) {
        vec2 from_center = SCREEN_UV - vec2(0.5);
        mask = pow(length(from_center) * 1.414, mask_falloff);
    }

    // Base step vector scaled by global strength, pulse, and mask
    vec2 base_offset = dir * strength * pulse * mask;

    // 4. Sample each channel with its own dedicated multiplier
    float r = texture(screen_texture, SCREEN_UV + (base_offset * red_shift)).r;
    float g = texture(screen_texture, SCREEN_UV + (base_offset * green_shift)).g;
    float b = texture(screen_texture, SCREEN_UV + (base_offset * blue_shift)).b;

    COLOR = vec4(r, g, b, 1.0);
}