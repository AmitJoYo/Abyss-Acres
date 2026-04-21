shader_type canvas_item;

// Grass wind sway shader — subtle UV oscillation to simulate wind.
uniform float wind_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wind_strength : hint_range(0.0, 0.05) = 0.015;
uniform float wind_scale : hint_range(1.0, 20.0) = 8.0;
uniform sampler2D grass_texture : filter_linear_mipmap, repeat_enable;

void fragment() {
    vec2 uv = UV;
    // Horizontal sway based on vertical position + time
    float sway = sin(uv.y * wind_scale + TIME * wind_speed) * wind_strength;
    // Add slight secondary wave for natural feel
    sway += sin(uv.y * wind_scale * 2.3 + TIME * wind_speed * 1.7) * wind_strength * 0.4;
    uv.x += sway;

    COLOR = texture(grass_texture, uv);
}
