shader_type canvas_item;

// Chromatic aberration — RGB channel split at screen edges only.
uniform float aberration_strength : hint_range(0.0, 0.02) = 0.008;
uniform float edge_start : hint_range(0.0, 0.5) = 0.3;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);

    // Mask: only apply near edges (beyond edge_start radius)
    float mask = smoothstep(edge_start, 0.7, dist);
    vec2 dir = normalize(uv - center) * aberration_strength * mask;

    float r = texture(screen_texture, uv + dir).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - dir).b;

    COLOR = vec4(r, g, b, 1.0);
}
