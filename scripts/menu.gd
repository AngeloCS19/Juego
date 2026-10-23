class_name Menu
extends Control
## Ventana sobre el juego: menú inicial, pausa y derrota. Cubre toda la pantalla y oscurece la sala,
## así los toques no llegan al mapa mientras está abierta. Los botones son grandes para el dedo.

var _titulo := Label.new()
var _texto := Label.new()
var _botones := VBoxContainer.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	centro.add_child(columna)

	_titulo.add_theme_font_size_override("font_size", 40)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_titulo)
	_texto.add_theme_font_size_override("font_size", 20)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size.x = 420
	columna.add_child(_texto)
	_botones.add_theme_constant_override("separation", 12)
	columna.add_child(_botones)
	hide()


## Muestra la ventana. "opciones" es una lista de [texto del botón, función que llama].
func mostrar(titulo: String, texto: String, opciones: Array) -> void:
	_titulo.text = titulo
	_texto.text = texto
	_texto.visible = texto != ""
	for b in _botones.get_children():
		b.queue_free()
	for o in opciones:
		var boton := BarraHabilidades.crear_boton(o[0], o[1])
		boton.custom_minimum_size = Vector2(320, 72)
		_botones.add_child(boton)
	show()
