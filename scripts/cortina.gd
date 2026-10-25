class_name Cortina
extends Control
## Transición entre salas: como un espejo que se cierra. Dos mitades oscuras avanzan desde los bordes
## hasta juntarse en el eje (una línea punteada celeste), se carga la sala siguiente y se vuelven a abrir.
## Al Reiniciar se cierra igual, pero en vez del eje gira en el centro una flecha circular hacia atrás.
## En el templo tutorial ("puerta") no hay espejo: una puerta doble se cierra de golpe en el centro y se abre
## (ajustada por Angelo en el banco de pruebas, artifact "Cortina de puerta").

const DURACION := 0.35  # segundos para cerrar (y otros tantos para abrir)
const DURACION_PUERTA := 0.5  # la puerta doble del tutorial es más lenta
const ESPERA_PUERTA := 0.35  # y se queda cerrada un poco más
const GOLPE := 0.75  # parte del cierre en que las hojas chocan; después rebotan un poco y vuelven
const SOMBRA_PUERTA := Color(0.16, 0.1, 0.06)
const OSCURO := Color(0.05, 0.04, 0.08)
const CELESTE := Color(0.55, 0.85, 1.0)

var cierre := 0.0:  # 0 abierta, 1 cerrada; el Tween la cambia y cada cambio redibuja
	set(valor):
		cierre = valor
		queue_redraw()
var flecha := -1.0:  # vuelta de la flecha de Reiniciar, de 0 a 1 (negativa: no hay flecha, se dibuja el eje)
	set(valor):
		flecha = valor
		queue_redraw()
var vertical := false  # true: las mitades vienen de los lados y se juntan en una línea vertical
var puerta := false  # templo tutorial: puerta doble en vez de espejo


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Cierra, llama a "en_medio" (cargar la sala nueva) con la pantalla tapada, y abre.
func pasar(eje_vertical: bool, en_medio: Callable, espera := 0.1) -> Tween:
	vertical = eje_vertical
	mouse_filter = Control.MOUSE_FILTER_STOP  # mientras dura, los toques no llegan al mapa
	var t := create_tween()
	if puerta:
		Sonido.tocar("puerta")  # el golpe del sonido está grabado justo en el momento GOLPE del cierre
		t.tween_method(_cerrar_de_golpe, 0.0, 1.0, DURACION_PUERTA)
		t.tween_callback(en_medio)
		t.tween_interval(maxf(espera, ESPERA_PUERTA))
		t.tween_property(self, "cierre", 0.0, DURACION_PUERTA).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(self, "cierre", 1.0, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(en_medio)
		t.tween_interval(espera)
		t.tween_property(self, "cierre", 0.0, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): mouse_filter = Control.MOUSE_FILTER_IGNORE)
	return t


## Reiniciar: la misma cortina, mientras la flecha da una vuelta hacia atrás en todo ese tiempo.
func rebobinar(eje_vertical: bool, en_medio: Callable) -> Tween:
	var t := pasar(eje_vertical, en_medio, 0.4)  # tapada un poco más, para ver girar la flecha
	var giro := create_tween()
	var d := DURACION_PUERTA * 2 + maxf(0.4, ESPERA_PUERTA) if puerta else DURACION * 2 + 0.4
	giro.tween_property(self, "flecha", 1.0, d).from(0.0)
	# Al terminar se quita la flecha, así el paso entre salas vuelve a mostrar el eje.
	# Va en este mismo Tween: si fuera en "t", este podría terminar después y dejar la flecha puesta.
	giro.tween_callback(func(): flecha = -1.0)
	return t


func activa() -> bool:
	return mouse_filter == Control.MOUSE_FILTER_STOP


func _draw() -> void:
	if cierre <= 0.0:
		return
	var s := size
	if puerta:
		_dibujar_puerta()
	elif vertical:
		var w := s.x * 0.5 * cierre
		draw_rect(Rect2(0, 0, w, s.y), OSCURO)
		draw_rect(Rect2(s.x - w, 0, w, s.y), OSCURO)
	else:
		var h := s.y * 0.5 * cierre
		draw_rect(Rect2(0, 0, s.x, h), OSCURO)
		draw_rect(Rect2(0, s.y - h, s.x, h), OSCURO)
	# El eje aparece cuando el espejo está casi cerrado.
	var brillo := clampf((cierre - 0.7) / 0.3, 0.0, 1.0)
	if brillo > 0.0 and flecha >= 0.0:
		_dibujar_flecha(brillo)
	elif brillo > 0.0 and not puerta:
		var a := Vector2(s.x / 2, 0) if vertical else Vector2(0, s.y / 2)
		var b := Vector2(s.x / 2, s.y) if vertical else Vector2(s.x, s.y / 2)
		draw_dashed_line(a, b, Color(CELESTE, brillo), 4.0, 18.0)


## Cierre con golpe: acelera hasta chocar en GOLPE, rebota un poco y vuelve a quedar cerrada.
func _cerrar_de_golpe(k: float) -> void:
	cierre = pow(k / GOLPE, 2) if k < GOLPE else 1.0 - 0.06 * sin((k - GOLPE) / (1.0 - GOLPE) * PI)


## Puerta doble: cada hoja crece desde su lado hasta juntarse en el centro. Desde la mitad del
## cierre se ven, tenues, las tablas y la argolla de cada hoja.
func _dibujar_puerta() -> void:
	var s := size
	var w := s.x * 0.5 * cierre
	draw_rect(Rect2(0, 0, w, s.y), SOMBRA_PUERTA)
	draw_rect(Rect2(s.x - w, 0, w, s.y), SOMBRA_PUERTA)
	var detalle := 0.2 * clampf((cierre - 0.5) / 0.5, 0.0, 1.0)
	if detalle <= 0.0:
		return
	var madera := Color(0.66, 0.43, 0.26, detalle)
	var argolla := Color(0.91, 0.73, 0.31, detalle)
	for lado in [[0.0, 1.0], [s.x, -1.0]]:  # [borde de la pantalla, hacia dónde crece la hoja]
		for i in range(1, 4):  # tres juntas entre las tablas
			var x: float = lado[0] + lado[1] * w * i / 4.0
			draw_line(Vector2(x, 0), Vector2(x, s.y), madera, 4.0)
		draw_arc(Vector2(lado[0] + lado[1] * w * 0.85, s.y * 0.55), 18.0, 0.0, TAU, 32, argolla, 4.0)


## Flecha de casi una vuelta, celeste como el eje, con la punta hacia atrás (sentido antihorario).
## Gira una vuelta completa hacia atrás, como rebobinando.
func _dibujar_flecha(brillo: float) -> void:
	var centro := size / 2
	var radio := minf(size.x, size.y) * 0.12
	var inicio := -PI / 2 - TAU * ease(flecha, -2.0)  # arranca y frena suave
	var color := Color(CELESTE, brillo)
	draw_arc(centro, radio, inicio + 0.3, inicio + TAU * 0.82, 48, color, radio * 0.16)
	# La punta, en el comienzo del arco, apunta en sentido antihorario (hacia atrás).
	var base := centro + Vector2.from_angle(inicio + 0.3) * radio
	var tangente := Vector2.from_angle(inicio + 0.3 - PI / 2)
	var normal := Vector2.from_angle(inicio + 0.3)
	draw_colored_polygon(PackedVector2Array([base + tangente * radio * 0.45, base + normal * radio * 0.32, base - normal * radio * 0.32]), color)
