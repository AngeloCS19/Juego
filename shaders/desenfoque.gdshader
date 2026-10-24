// Desenfoca lo que ya está dibujado detrás (la sala y la hotbar).
// Promedia muestras de la pantalla en un círculo alrededor de cada píxel: cuanto mayor "radio", más borroso.
shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform float radio = 6.0;  // en píxeles

void fragment() {
	vec4 suma = vec4(0.0);
	float total = 0.0;
	for (int anillo = 0; anillo <= 3; anillo++) {
		float r = radio * float(anillo) / 3.0;
		int puntos = anillo == 0 ? 1 : 8 * anillo;
		for (int k = 0; k < puntos; k++) {
			float a = 6.2832 * float(k) / float(puntos);
			suma += texture(pantalla, SCREEN_UV + vec2(cos(a), sin(a)) * r * SCREEN_PIXEL_SIZE);
			total += 1.0;
		}
	}
	COLOR = vec4((suma / total).rgb * 0.8, 1.0);  // un poco más oscuro, para que el nombre resalte
}
