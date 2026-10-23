class_name Cortina
extends Control
## Transición entre salas: como un espejo que se cierra. Dos mitades oscuras avanzan desde los bordes
## hasta juntarse en el eje (una línea punteada celeste), se carga la sala siguiente y se vuelven a abrir.

const DURACION := 0.35  # segundos para cerrar (y otros tantos para abrir)
const OSCURO := Color(0.05, 0.04, 0.08)
const CELESTE := Color(0.55, 0.85, 1.0)

var cierre := 0.0:  # 0 abierta, 1 cerrada; el Tween la cambia y cada cambio redibuja
	set(valor):
		cierre = valor
		queue_redraw()
var vertical := false  # true: las mitades vienen de los lados y se juntan en una línea vertical


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Cierra, llama a "en_medio" (cargar la sala nueva) con la pantalla tapada, y abre.
func pasar(eje_vertical: bool, en_medio: Callable) -> Tween:
	vertical = eje_vertical
	mouse_filter = Control.MOUSE_FILTER_STOP  # mientras dura, los toques no llegan al mapa
	var t := create_tween()
	t.tween_property(self, "cierre", 1.0, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(en_medio)
	t.tween_interval(0.1)
	t.tween_property(self, "cierre", 0.0, DURACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): mouse_filter = Control.MOUSE_FILTER_IGNORE)
	return t


func activa() -> bool:
	return mouse_filter == Control.MOUSE_FILTER_STOP


func _draw() -> void:
	if cierre <= 0.0:
		return
	var s := size
	if vertical:
		var w := s.x * 0.5 * cierre
		draw_rect(Rect2(0, 0, w, s.y), OSCURO)
		draw_rect(Rect2(s.x - w, 0, w, s.y), OSCURO)
	else:
		var h := s.y * 0.5 * cierre
		draw_rect(Rect2(0, 0, s.x, h), OSCURO)
		draw_rect(Rect2(0, s.y - h, s.x, h), OSCURO)
	# El eje aparece cuando el espejo está casi cerrado.
	var brillo := clampf((cierre - 0.7) / 0.3, 0.0, 1.0)
	if brillo > 0.0:
		var a := Vector2(s.x / 2, 0) if vertical else Vector2(0, s.y / 2)
		var b := Vector2(s.x / 2, s.y) if vertical else Vector2(s.x, s.y / 2)
		draw_dashed_line(a, b, Color(CELESTE, brillo), 4.0, 18.0)
