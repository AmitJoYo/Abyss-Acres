shader_type canvas_item;

// Water distortion shader — sin-wave UV offset for underwater feel.
uniform float distortion_speed : hint_range(0.1, 3.0) = 0.8;
uniform float distortion_strength : hint_range(0.0, 0.03) = 0.012;
uniform float wave_scale_x : hint_range(1.0, 30.0) = 12.0;
uniform float wave_scale_y : hint_range(1.0, 30.0) = 10.0;
uniform vec4 tint_color : source_color = vec4(0.05, 0.08, 0.2, 1.0);
uniform float tint_strength : hint_range(0.0, 0.5) = 0.15;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Two overlapping sine waves for organic motion
    float offset_x = sin(uv.y * wave_scale_y + TIME * distortion_speed) * distortion_strength;
    float offset_y = cos(uv.x * wave_scale_x + TIME * distortion_speed * 0.7) * distortion_strength * 0.8;

    vec2 distorted_uv = uv + vec2(offset_x, offset_y);
    vec4 col = texture(screen_texture, distorted_uv);

    // Subtle deep-blue tint overlay
    col.rgb = mix(col.rgb, tint_color.rgb, tint_strength);

    // Darken edges for vignette depth
    float vignette = distance(uv, vec2(0.5));
    col.rgb *= 1.0 - vignette * 0.4;

    COLOR = col;
}
