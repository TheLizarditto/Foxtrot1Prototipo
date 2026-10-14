shader_type canvas_item;

uniform vec4 color_destello : source_color = vec4(1.0);
uniform float intensidad : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// COLOR ya incluye la textura y la modulacion del sprite.
	vec4 original = COLOR;
	COLOR = vec4(mix(original.rgb, color_destello.rgb, intensidad), original.a);
}
