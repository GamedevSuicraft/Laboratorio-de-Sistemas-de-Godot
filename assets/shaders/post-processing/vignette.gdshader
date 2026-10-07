shader_type canvas_item;

// --- SHADER INTERFACE ---

/** 
 * [DO NOT EDIT] Captures the game screen buffer underneath this canvas item layer.
 */
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

/** 
 * If enabled, the vignette will be inverted, darkening the center instead of the edges.
 */
uniform bool invert_vignette = false;

/** 
 * Controls how far the darkness reaches.
 * Higher values push the darkness away. Lower values bring it closer.
 */
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.8;

/** 
 * Controls the softness of the transition.
 * Higher values make the blur smoother, lower values create a sharp, hard border.
 */
uniform float vignette_softness : hint_range(0.0, 2.0) = 0.5;

/** 
 * Adjusts the shape of the vignette to match widescreen aspect ratios.
 * 1.77 is ideal for 16:9 screens to keep the vignette perfectly circular.
 */
uniform float vignette_aspect_ratio : hint_range(0.5, 3.0) = 1.77;

/** 
 * The color tint applied to the vignette. 
 */
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);


// --- MATHEMATICAL PROCESSING ---

void fragment() {
    // 1. Fetch the original color from the game screen
    vec4 current_color = texture(screen_texture, SCREEN_UV);
    
    // 2. Center coordinates: (0.0, 0.0) is now the exact middle of the screen
    vec2 center_uv = SCREEN_UV - vec2(0.5);
    
    // 3. Apply aspect ratio correction so it doesn't stretch into an oval
    center_uv.x *= vignette_aspect_ratio;
    
    // 4. Calculate the real distance from the center
    float dist = length(center_uv);
    
    // 5. Calculate the base vignette factor
    float vignette_factor = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);
    
    // 6. Mathematically invert the factor if the boolean is checked
    if (invert_vignette) {
        vignette_factor = 1.0 - vignette_factor;
    }
    
    // 7. Blend the game screen with the vignette color
    vec3 final_rgb = mix(current_color.rgb, vignette_color.rgb, vignette_factor);
    
    COLOR = vec4(final_rgb, 1.0);
}
