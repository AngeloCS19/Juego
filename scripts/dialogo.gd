class_name Dialogo
extends Control
## Ventana de diálogo, al estilo de Hades: el retrato grande del personaje a la izquierda,
## su nombre en una placa y el texto en un recuadro abajo. Tocar la pantalla (o Espacio/Enter)
## muestra todo el texto si todavía se está escribiendo, o pasa a la siguiente línea.
##
## Las líneas vienen de los JSON de las salas: [{"quien": "narciso", "animo": "sereno", "texto": "..."}].

signal terminado

## Quién puede hablar: su nombre, un título corto, su letra y cómo se ve cada ánimo.
## Cada personaje tiene una tipografía que dice cómo es (en assets/fuentes/, con su licencia OFL).
## Un ánimo elige el retrato y, si "tiembla", las letras se sacuden (la ira de Narciso en la huida).
## Para un personaje nuevo basta con agregarlo aquí y dibujar sus retratos en assets/retratos/.
const PERSONAJES := {
	"narciso": {
		"nombre": "Narciso",
		"titulo": "Espíritu del río",
		# Cursiva fina y elegante, de libro antiguo: Narciso es vanidoso y refinado.
		"fuente": preload("res://assets/fuentes/CormorantGaramond-SemiBoldItalic.ttf"),
		"tamano": 36,
		"animos": {
			"sereno": {"retrato": preload("res://assets/retratos/narciso_retrato.svg")},
			"enojado": {"retrato": preload("res://assets/retratos/narciso_retrato_enojado.svg")},
			"furioso": {"retrato": preload("res://assets/retratos/narciso_retrato_furioso.svg"), "tiembla": true},  # ya sin flores: las perdió en el jefe
		},
	},
}
## Los nombres van en mayúsculas romanas, como grabados en piedra.
const FUENTE_NOMBRE := preload("res://assets/fuentes/Cinzel-Bold.ttf")
const LETRAS_POR_SEGUNDO := 45.0
const ORO := Color(0.91, 0.73, 0.31)

var _lineas: Array = []
var _i := 0
var _retrato := TextureRect.new()
var _nombre := Label.new()
var _titulo := Label.new()
var _texto := RichTextLabel.new()  # Rich: permite efectos como [shake]
var _escribir: Tween


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # los toques no llegan al mapa
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	# El retrato ocupa casi toda la altura, pegado abajo a la izquierda. Las anclas son fracciones de la pantalla.
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anclar(_retrato, 0.0, 0.08, 0.38, 1.0)
	add_child(_retrato)

	# El recuadro del texto: papel claro con borde dorado, abajo a la derecha del retrato.
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", _estilo(Color(0.96, 0.94, 0.89), ORO, 5, 28))
	_anclar(caja, 0.3, 0.68, 0.97, 0.96)
	add_child(caja)
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_color_override("default_color", Color(0.17, 0.1, 0.08))
	caja.add_child(_texto)

	# La placa con el nombre, encima del recuadro.
	var placa := PanelContainer.new()
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_theme_stylebox_override("panel", _estilo(Color(0.17, 0.1, 0.08), ORO, 4, 14))
	_anclar(placa, 0.32, 0.55, 0.32, 0.68)
	placa.grow_horizontal = Control.GROW_DIRECTION_END
	add_child(placa)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 0)
	placa.add_child(columna)
	_nombre.add_theme_font_override("font", FUENTE_NOMBRE)
	_nombre.add_theme_font_size_override("font_size", 34)
	_nombre.add_theme_color_override("font_color", ORO)
	_nombre.uppercase = true
	columna.add_child(_nombre)
	_titulo.add_theme_font_size_override("font_size", 18)
	_titulo.add_theme_color_override("font_color", Color(0.85, 0.55, 0.45))
	columna.add_child(_titulo)
	hide()


## Empieza una conversación. Si no hay líneas, avisa que terminó de una vez.
func mostrar(lineas: Array) -> void:
	_lineas = lineas
	_i = 0
	if _lineas.is_empty():
		terminado.emit()
		return
	show()
	_mostrar_linea()


func avanzar() -> void:
	if _escribir and _escribir.is_running():
		_escribir.kill()
		_texto.visible_ratio = 1.0
		return
	_i += 1
	if _i < _lineas.size():
		_mostrar_linea()
	else:
		hide()
		terminado.emit()


func _mostrar_linea() -> void:
	var linea: Dictionary = _lineas[_i]
	var quien: Dictionary = PERSONAJES[linea["quien"]]
	var animo: Dictionary = quien["animos"][linea.get("animo", "sereno")]
	_retrato.texture = animo["retrato"]
	_nombre.text = quien["nombre"]
	_titulo.text = quien["titulo"]
	_titulo.add_theme_font_override("font", quien["fuente"])
	_texto.add_theme_font_override("normal_font", quien["fuente"])
	_texto.add_theme_font_size_override("normal_font_size", quien["tamano"])
	var texto: String = linea["texto"].replace("[", "[lb]")  # un corchete del JSON no debe leerse como efecto
	if animo.get("tiembla", false):
		texto = "[color=#7a1a10][shake rate=25.0 level=10 connected=1]%s[/shake][/color]" % texto
	_texto.text = texto
	# El texto aparece letra por letra: visible_ratio va de 0 (nada) a 1 (todo).
	_texto.visible_ratio = 0.0
	_escribir = create_tween()
	_escribir.tween_property(_texto, "visible_ratio", 1.0, _texto.get_total_character_count() / LETRAS_POR_SEGUNDO)


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		avanzar()
		accept_event()


func _anclar(nodo: Control, izquierda: float, arriba: float, derecha: float, abajo: float) -> void:
	nodo.anchor_left = izquierda
	nodo.anchor_top = arriba
	nodo.anchor_right = derecha
	nodo.anchor_bottom = abajo


func _estilo(fondo: Color, borde: Color, grosor: int, margen: int) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(4)
	e.set_content_margin_all(margen)
	return e
