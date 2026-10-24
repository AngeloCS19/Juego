class_name BarraHabilidades
extends HBoxContainer
## Hotbar de habilidades (abajo al centro, como las de un MOBA): una casilla cuadrada por habilidad
## ya desbloqueada, con su icono y el número de su tecla. Solo una está activa a la vez (borde dorado y brillo),
## y no se puede cambiar mientras la activa siga en curso. Las casillas se tocan en el celular.

signal pedida(i: int)  # el jugador tocó la habilidad i
signal nueva(h: Habilidad)  # el jugador consigue una habilidad por primera vez

const COLOR_ACTIVA := Color(0.95, 0.75, 0.3)
const COLOR_NORMAL := Color(0.4, 0.4, 0.45)
const TAM_BOTON := Vector2(72, 64)  # tamaño mínimo cómodo para un dedo
const TAM_CASILLA := Vector2(72, 72)

var habilidades: Array[Habilidad] = []
var activa := 0
var boton_usar: Button  # main.gd lo crea; aquí se le cambia el icono por el de la habilidad activa
var _botones: Array[Button] = []
var _estilos: Array[StyleBoxFlat] = []
var _pendientes := {}  # índices de habilidades recién conseguidas: su casilla espera al anuncio (invisible pero con su lugar)
var _pulsos := {}  # índice -> Tween de la casilla que brilla dilatándose (tutorial)
var _pulsar := {}  # nombres (en minúsculas) de las habilidades que deben brillar
var _bloqueada := false  # en el plano espiritual solo Traspasar se puede tocar
static var _vistas := {}  # habilidades ya anunciadas
static var _conocidos := {}  # nombres de los botones que el jugador ya tocó: esos ya no muestran texto


func _init(p_habilidades: Array[Habilidad]) -> void:
	habilidades = p_habilidades
	add_theme_constant_override("separation", 8)
	for i in habilidades.size():
		var boton := Button.new()
		boton.custom_minimum_size = TAM_CASILLA
		boton.pivot_offset = TAM_CASILLA / 2  # el pulso dilata desde el centro
		boton.icon = _icono(habilidades[i])
		boton.expand_icon = true
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.add_theme_constant_override("icon_max_width", 48)
		boton.tooltip_text = habilidades[i].nombre
		boton.focus_mode = Control.FOCUS_NONE
		boton.pressed.connect(pedida.emit.bind(i))
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0.05, 0.04, 0.05, 0.85)
		estilo.set_corner_radius_all(6)
		estilo.shadow_color = Color(COLOR_ACTIVA, 0.0)
		for estado in ["normal", "hover", "pressed", "disabled"]:
			boton.add_theme_stylebox_override(estado, estilo)
		# El número de la tecla, pequeño, en la esquina inferior izquierda.
		var tecla := Label.new()
		tecla.text = str(i + 1)
		tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tecla.add_theme_font_size_override("font_size", 16)
		tecla.add_theme_color_override("font_outline_color", Color.BLACK)
		tecla.add_theme_constant_override("outline_size", 5)
		tecla.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 5)
		boton.add_child(tecla)
		add_child(boton)
		_botones.append(boton)
		_estilos.append(estilo)
	_pintar()


## Botón con el estilo del juego. Lo usa la barra y también main.gd para los demás controles.
## Con icono, "texto" es el nombre: se ve solo hasta el primer toque, y queda como ayuda al pasar el mouse.
static func crear_boton(texto: String, accion: Callable, borde := COLOR_NORMAL, icono: Texture2D = null) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = TAM_BOTON
	if icono:
		boton.icon = icono
		boton.tooltip_text = texto
		boton.add_theme_constant_override("icon_max_width", 48)
		if _conocidos.has(texto):
			boton.text = ""
		boton.pressed.connect(func():
			_conocidos[texto] = true
			boton.text = "")
	boton.focus_mode = Control.FOCUS_NONE  # si no, Espacio "presionaría" el último botón tocado
	boton.add_theme_font_size_override("font_size", 22)
	_estilo(boton, borde, 1)
	boton.pressed.connect(accion)
	return boton


## Deja disponibles solo las habilidades cuyo nombre (en minúsculas) está en la lista.
## Cada sala dice cuáles tiene en su JSON, en "habilidades".
func configurar(disponibles: Array) -> void:
	for h in habilidades:
		h.disponible = h.nombre.to_lower() in disponibles
		if h.disponible and not _vistas.has(h.nombre):
			_vistas[h.nombre] = true
			_pendientes[habilidades.find(h)] = true
			nueva.emit(h)
	if not habilidades[activa].disponible:
		activa = 0
	_pintar()


## Intenta activar la habilidad i. Devuelve false si no se puede.
func elegir(i: int, sala: Sala) -> bool:
	if i < 0 or i >= habilidades.size() or not habilidades[i].disponible:
		return false
	if i != activa and habilidades[activa].en_curso(sala):
		return false
	activa = i
	_pintar()
	return true


## Apaga (o enciende) todos los botones menos el de la habilidad activa.
func bloquear(valor: bool) -> void:
	_bloqueada = valor
	_pintar()


func usar(sala: Sala) -> void:
	if sala.cayendo():
		return
	habilidades[activa].usar(sala)


## El icono de cada habilidad es assets/sprites/icono_<nombre>.svg.
func _icono(h: Habilidad) -> Texture2D:
	return load("res://assets/sprites/icono_%s.svg" % h.nombre.to_lower())


func icono_activa() -> Texture2D:
	return _icono(habilidades[activa])


## La casilla de la habilidad i es la que se ve cuando el anuncio termina de volar hasta ella.
func casilla(i: int) -> Button:
	return _botones[i]


## Muestra la casilla de una habilidad recién conseguida (la que esperaba al anuncio), con un saltito.
func revelar(i: int) -> void:
	_pendientes.erase(i)
	_pintar()
	var t := _botones[i].create_tween()
	t.tween_property(_botones[i], "scale", Vector2.ONE * 1.25, 0.1)
	t.tween_property(_botones[i], "scale", Vector2.ONE, 0.15)


## Hace brillar (o deja de hacerlo) la casilla de la habilidad con ese nombre: pista visual del tutorial.
func pulsar(nombre: String, activo: bool) -> void:
	if activo:
		_pulsar[nombre.to_lower()] = true
	else:
		_pulsar.erase(nombre.to_lower())
	_pintar()


func _pintar() -> void:
	if boton_usar:
		boton_usar.icon = icono_activa()
	for i in _botones.size():
		var h := habilidades[i]
		var libre := h.disponible and not (_bloqueada and i != activa)
		var es_activa := i == activa and libre
		var boton := _botones[i]
		boton.visible = h.disponible  # solo las ya desbloqueadas
		boton.disabled = not libre
		# Activa: clara, con borde dorado grueso y brillo. Disponible: normal. Apagada (plano espiritual): oscura.
		var tono := 1.0 if es_activa else (0.7 if libre else 0.3)
		boton.modulate = Color(tono, tono, tono, 0.0 if _pendientes.has(i) else 1.0)
		var estilo := _estilos[i]
		estilo.border_color = COLOR_ACTIVA if es_activa else COLOR_NORMAL
		estilo.set_border_width_all(4 if es_activa else 2)
		estilo.shadow_size = 8 if es_activa else 0
		estilo.shadow_color = Color(COLOR_ACTIVA, 0.55)
		var brilla: bool = _pulsar.has(h.nombre.to_lower()) and boton.is_inside_tree()
		if brilla and not _pulsos.has(i):
			_pulsos[i] = _crear_pulso(boton, estilo)
		elif not brilla and _pulsos.has(i):
			_pulsos[i].kill()
			_pulsos.erase(i)
			boton.scale = Vector2.ONE
			boton.self_modulate = Color.WHITE


## Bucle de brillo: la casilla se dilata y se ilumina, y vuelve.
func _crear_pulso(boton: Button, estilo: StyleBoxFlat) -> Tween:
	var paso := func(k: float):
		boton.scale = Vector2.ONE * (1.0 + 0.2 * k)
		boton.self_modulate = Color.WHITE.lerp(Color(1.8, 1.6, 1.1), k)
		estilo.shadow_size = int(8 + 14 * k)
		estilo.shadow_color = Color(COLOR_ACTIVA, 0.4 + 0.5 * k)
	var t := boton.create_tween().set_loops()
	t.tween_method(paso, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	t.tween_method(paso, 1.0, 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	return t


static func _estilo(boton: Button, borde: Color, grosor: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.55)
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(12)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		boton.add_theme_stylebox_override(estado, estilo)
