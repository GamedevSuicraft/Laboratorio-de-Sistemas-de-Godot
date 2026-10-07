shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

/** 
 * Select the mathematical algorithm used to convert colors into grayscale or black and white.
 * 1. Simple Average: Sum of all color channels divided by 3 (R+G+B / 3).
 * 2. Luminosity: Weights based on human eye perception (Rec. 709). Most natural look.
 * 3. Lightness HSL: Average of the highest and lowest color channels (Max+Min / 2).
 * 4. Pure B&W Binarization: Drops all gray midtones based on the threshold cutoff value.
 */
uniform int select_grayscale_math_algorithm : hint_enum(
    "1. Simple Average (R+G+B / 3)", 
    "2. Luminosity (Human Vision Weights)", 
    "3. Lightness HSL (Max+Min / 2)", 
    "4. Pure B&W Binarization (Uses Threshold below)"
) = 1;

/** 
 * The cutoff intensity limit used ONLY when "4. Pure B&W Binarization" is active.
 * Pixel brightness values below this factor will snap to pure black (0.0).
 * Pixel brightness values equal or above this factor will snap to pure white (1.0).
 */
uniform float binarization_threshold_cutoff : hint_range(0.0, 1.0) = 0.5;


void fragment() {
    vec4 current_color = texture(screen_texture, SCREEN_UV);
    float gray_result = 0.0;
    
    if (select_grayscale_math_algorithm == 0) {
        gray_result = (current_color.r + current_color.g + current_color.b) / 3.0;
    } 
    else if (select_grayscale_math_algorithm == 1) {
        gray_result = dot(current_color.rgb, vec3(0.299, 0.587, 0.114));
    } 
    else if (select_grayscale_math_algorithm == 2) {
        float max_val = max(current_color.r, max(current_color.g, current_color.b));
        float min_val = min(current_color.r, min(current_color.g, current_color.b));
        gray_result = (max_val + min_val) / 2.0;
    } 
    else if (select_grayscale_math_algorithm == 3) {
        float base_luminosity = dot(current_color.rgb, vec3(0.299, 0.587, 0.114));
        gray_result = step(binarization_threshold_cutoff, base_luminosity);
    }
    
    COLOR = vec4(vec3(gray_result), 1.0);
}
