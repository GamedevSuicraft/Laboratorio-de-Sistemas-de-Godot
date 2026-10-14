shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width: hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Increase the mesh slightly outwards following the normals
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	// Paint the mesh with a solid black color
	ALBEDO = outline_color.rgb;
}
