shader_type sky;

// Arraste a sua imagem do céu para este slot no painel lateral
uniform sampler2D sky_texture : source_color, filter_linear_mipmap;

void sky() {
    // Converte a direção do olhar da câmera (EYEDIR) em coordenadas UV esféricas
    float phi = atan(EYEDIR.z, EYEDIR.x);
    float theta = acos(EYEDIR.y);
    
    // Normaliza para o espaço UV (0.0 a 1.0)
    vec2 uv = vec3(phi / (2.0 * PI) + 0.5, theta / PI, 0.0).xy;
    
    // Aplica a textura no céu
    COLOR = texture(sky_texture, uv).rgb;
}