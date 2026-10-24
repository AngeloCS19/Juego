class_name BarraHabilidades
extends HBoxContainer
## Barra con las habilidades del jugador. Solo una está activa a la vez,
## y no se puede cambiar mientras la activa siga en curso.
## Cada habilidad es un botón grande, para poder tocarlo en el celular.
## Los botones son solo iconos: el nombre aparece al lado hasta que el jugador lo toca la primera vez.

signal pedida(i: int)  # el jugador tocó la habilidad i

const COLOR_ACTIVA := Color(0.95, 0.75, 0.3)
const COLOR_NORMAL := Color(0.4, 0.4, 0.45)
const TAM_BOTON := Vector2(72, 64)  # tamaño mínimo cómodo para un dedo

var habilidades: Array[Habilidad] = []
var activa := 0
var boton_usar: Button  # main.gd lo crea; aquí se le cambia el icono por el de la habilidad activa
var _botones: Array[Button] = []
static var _conocidos := {}  # nombres de los botones que el jugador ya tocó: esos ya no muestran texto


func _init(p_habilidades: Array[Habilidad]) -> void:
	habilidades = p_habilidades
	add_theme_constant_override("separation", 8)
	for i in habilidades.size():
		var boton := crear_boton(habilidades[i].nombre, pedida.emit.bind(i), COLOR_NORMAL, _icono(habilidades[i]))
		add_child(boton)
		_botones.append(boton)
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


func usar(sala: Sala) -> void:
	if sala.cayendo():
		return
	habilidades[activa].usar(sala)


## El icono de cada habilidad es assets/sprites/icono_<nombre>.svg.
func _icono(h: Habilidad) -> Texture2D:
	return load("res://assets/sprites/icono_%s.svg" % h.nombre.to_lower())


func icono_activa() -> Texture2D:
	return _icono(habilidades[activa])


func _pintar() -> void:
	if boton_usar:
		boton_usar.icon = icono_activa()
	for i in _botones.size():
		_botones[i].disabled = not habilidades[i].disponible
		_botones[i].modulate.a = 1.0 if habilidades[i].disponible else 0.4
		_estilo(_botones[i], COLOR_ACTIVA if i == activa else COLOR_NORMAL, 3 if i == activa else 1)


static func _estilo(boton: Button, borde: Color, grosor: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.55)
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(12)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		boton.add_theme_stylebox_override(estado, estilo)
