shader_type canvas_item;

/**
 * Access the rendered screen behind this object.
 */
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

group_uniforms Shockwave;

/**
 * Center position of the blast in normalized screen coordinates (0.5, 0.5 is screen center).
 */
uniform vec2 center = vec2(0.5, 0.5);

/**
 * Current radius of the wave. Animate this from 0.0 to 1.0 using a Tween.
 */
uniform float radius : hint_range(0.0, 1.0) = 0.2;

/**
 * Thickness of the distortion band.
 */
uniform float band_thickness : hint_range(0.01, 0.2) = 0.05;

/**
 * Refraction/bending strength.
 */
uniform float force : hint_range(-0.1, 0.1) = 0.03;

void fragment() {
    // 1. Vector and distance from the shockwave epicenter
    vec2 to_pixel = SCREEN_UV - center;
    float dist = length(to_pixel);

    // 2. Identify if the current pixel is inside the expanding ring
    // smoothstep creates a smooth bell-curve mask around 'radius'
    float mask = smoothstep(radius - band_thickness, radius, dist) 
               * (1.0 - smoothstep(radius, radius + band_thickness, dist));

    // 3. Push pixel coordinates outward along the direction from center
    vec2 dir = (dist > 0.0001) ? normalize(to_pixel) : vec2(0.0);
    vec2 distorted_uv = SCREEN_UV + (dir * mask * force);

    // 4. Sample the background with distorted coordinates
    COLOR = texture(screen_texture, distorted_uv);
}