class_name BarraHabilidades
extends HBoxContainer
## Barra con las habilidades del jugador. Solo una está activa a la vez,
## y no se puede cambiar mientras la activa siga en curso.

const COLOR_ACTIVA := Color(0.95, 0.75, 0.3)
const COLOR_NORMAL := Color(0.4, 0.4, 0.45)

var habilidades: Array[Habilidad] = []
var activa := 0
var _casillas: Array[PanelContainer] = []


func _init(p_habilidades: Array[Habilidad]) -> void:
	habilidades = p_habilidades
	add_theme_constant_override("separation", 8)
	for i in habilidades.size():
		var casilla := PanelContainer.new()
		var texto := Label.new()
		texto.text = "%d · %s" % [i + 1, habilidades[i].nombre]
		if not habilidades[i].disponible:
			texto.text += " (bloqueada)"
			casilla.modulate.a = 0.4
		casilla.add_child(texto)
		add_child(casilla)
		_casillas.append(casilla)
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
	habilidades[activa].usar(sala)


func _pintar() -> void:
	for i in _casillas.size():
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0, 0, 0, 0.5)
		estilo.border_color = COLOR_ACTIVA if i == activa else COLOR_NORMAL
		estilo.set_border_width_all(3 if i == activa else 1)
		estilo.set_content_margin_all(8)
		_casillas[i].add_theme_stylebox_override("panel", estilo)
