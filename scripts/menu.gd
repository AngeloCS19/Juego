class_name Menu
extends Control
## Ventana sobre el juego: menú inicial, pausa y derrota. Cubre toda la pantalla y oscurece la sala,
## así los toques no llegan al mapa mientras está abierta. Los botones son grandes para el dedo.
## El menú inicial muestra detrás una ilustración fija del templo; la pausa y la derrota solo oscurecen.

const ILUSTRACION := preload("res://assets/ilustracion_templo.svg")
const FUENTE_TITULO := preload("res://assets/fuentes/Cinzel-Bold.ttf")  # mayúsculas romanas, aire griego
const ORO := Color(0.95, 0.82, 0.45)

var _ilustracion := TextureRect.new()
var _fondo := ColorRect.new()
var _titulo := Label.new()
var _texto := Label.new()
var _fila := HBoxContainer.new()  # retratos para elegir personaje (solo el menú inicial)
var _caras: Array[Button] = []
var _elegido := 0
var _al_elegir: Callable


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# La ilustración llena la pantalla recortando lo que sobre, para que no se deforme.
	_ilustracion.texture = ILUSTRACION
	_ilustracion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ilustracion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_ilustracion.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ilustracion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ilustracion)

	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	# Los textos y botones van en un recuadro oscuro con borde dorado, para que se lean sobre la ilustración.
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.04, 0.03, 0.82)
	estilo.border_color = ORO
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(36)
	caja.add_theme_stylebox_override("panel", estilo)
	centro.add_child(caja)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	caja.add_child(columna)

	_titulo.add_theme_font_override("font", FUENTE_TITULO)
	_titulo.add_theme_font_size_override("font_size", 44)
	_titulo.add_theme_color_override("font_color", ORO)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_titulo)
	_texto.add_theme_font_size_override("font_size", 20)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size.x = 420
	columna.add_child(_texto)
	_fila.alignment = BoxContainer.ALIGNMENT_CENTER
	_fila.add_theme_constant_override("separation", 16)
	columna.add_child(_fila)
	_botones.add_theme_constant_override("separation", 12)
	columna.add_child(_botones)
	hide()


## Muestra la ventana. "opciones" es una lista de [texto del botón, función que llama].
## "ilustrado" (el menú inicial) deja ver el templo detrás; si no, solo se oscurece la sala.
## "retratos" (opcional) son las imágenes entre las que se elige: tocar una (o izquierda/derecha) llama a "al_elegir(índice)".
func mostrar(titulo: String, texto: String, opciones: Array, ilustrado := false, retratos: Array = [], elegido := 0, al_elegir := Callable()) -> void:
	_ilustracion.visible = ilustrado
	_fondo.color = Color(0, 0, 0, 0.35) if ilustrado else Color(0, 0, 0, 0.72)
	_titulo.text = titulo
	_texto.text = texto
	_texto.visible = texto != ""
	for b in _botones.get_children():
		b.queue_free()
	for c in _caras:
		c.queue_free()
	_caras.clear()
	_elegido = elegido
	_al_elegir = al_elegir
	for i in retratos.size():
		var cara := Button.new()
		cara.icon = retratos[i]
		cara.expand_icon = true
		cara.custom_minimum_size = Vector2(104, 104)
		cara.focus_mode = Control.FOCUS_NONE
		cara.pressed.connect(_elegir.bind(i))
		_fila.add_child(cara)
		_caras.append(cara)
	_marcar()
	for o in opciones:
		var boton := BarraHabilidades.crear_boton(o[0], o[1])
		boton.custom_minimum_size = Vector2(320, 72)
		_botones.add_child(boton)
	show()


func _elegir(i: int) -> void:
	_elegido = i
	_marcar()
	_al_elegir.call(i)


## El elegido lleva borde dorado grueso; los demás, uno discreto y más oscuro.
func _marcar() -> void:
	for i in _caras.size():
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.2, 0.14, 0.1, 0.9) if i == _elegido else Color(0.1, 0.07, 0.05, 0.6)
		estilo.border_color = ORO if i == _elegido else Color(0.4, 0.3, 0.2)
		estilo.set_border_width_all(5 if i == _elegido else 2)
		estilo.set_corner_radius_all(10)
		estilo.set_content_margin_all(6)
		if i == _elegido:
			estilo.shadow_color = Color(ORO, 0.55)
			estilo.shadow_size = 10
		for n in ["normal", "hover", "pressed"]:
			_caras[i].add_theme_stylebox_override(n, estilo)
		_caras[i].modulate = Color.WHITE if i == _elegido else Color(0.75, 0.75, 0.75)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not visible or _caras.is_empty() or not evento.pressed or evento.echo:
		return
	if evento.keycode in [KEY_LEFT, KEY_RIGHT]:
		_elegir(clampi(_elegido + (1 if evento.keycode == KEY_RIGHT else -1), 0, _caras.size() - 1))
		get_viewport().set_input_as_handled()
