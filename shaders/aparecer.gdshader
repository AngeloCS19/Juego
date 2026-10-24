// Hace aparecer un dibujo de abajo hacia arriba con un borde suave.
// "borde" es la altura de la línea de aparición en la pantalla (0 = arriba, 1 = abajo): lo de debajo se ve, lo de encima no.
// Como usa la altura en pantalla (SCREEN_UV) y no la del dibujo, la cabeza y sus flores comparten la misma línea.
shader_type canvas_item;

uniform float borde = 1.0;
uniform float suave = 0.06;  // alto de la franja difuminada

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.a *= smoothstep(borde - suave, borde + suave, SCREEN_UV.y);
	COLOR = c;
}
