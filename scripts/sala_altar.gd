class_name SalaAltar
extends Sala
## El altar de Narciso, afuera del templo: su estatua mira un estanque. En el plano espiritual,
## el reflejo de la estatua aparece vestido con sus cuatro prendas. Hay que poner cada prenda
## alrededor de la estatua y marcarla con Reflejo, para que su reflejo caiga donde el reflejo
## vestido la muestra. Cuando estatua y reflejo coinciden, el alma de Narciso descansa.
##
## El JSON lleva "tipo": "altar" y además:
##   "estatua": casilla de la estatua (una piedra fija que se dibuja como Narciso)
##   piedras con "prenda": las prendas, que se empujan como piedras
##   "reflejo_vestido": {"prenda": casilla} donde el reflejo vestido muestra cada prenda
## Gana cuando todas las prendas están marcadas y su reflejo cae en su casilla.

const TEX_ESTATUA := preload("res://assets/sprites/estatua.svg")
const TEX_FLOR := preload("res://assets/sprites/flor_narciso.svg")

var en_paz := false


func reiniciar() -> void:
	super()
	en_paz = false
	# Las piedras salen en el mismo orden que en el JSON: se les agrega qué prenda o estatua son.
	var lista: Array = datos["piedras"]
	for i in lista.size():
		piedras[i]["prenda"] = lista[i].get("prenda", "")
	piedras.append({"pos": _vec(datos["estatua"]), "fija": true, "flota": false, "marcada": false, "prenda": "", "estatua": true})


## Las prendas no se echan al estanque: solo se empujan sobre el pasto.
func _empujar(i: int, dir: Vector2i) -> bool:
	if celda(piedras[i]["pos"] + dir) != ".":
		return false
	return super(i, dir)


func _turno() -> void:
	if not en_paz and _vestida():
		en_paz = true
		queue_redraw()
		completada.emit()


func _vestida() -> bool:
	var destinos: Dictionary = datos["reflejo_vestido"]
	for p in piedras:
		if p["prenda"] == "":
			continue
		if not p["marcada"] or transformaciones[0].aplicar(p["pos"]) != _vec(destinos[p["prenda"]]):
			return false
	return true


func _tex_piedra(p: Dictionary) -> Texture2D:
	if p.get("estatua", false):
		return TEX_ESTATUA
	if p.get("prenda", "") != "":
		return TEX_PRENDA[p["prenda"]]
	return super(p)


func _draw() -> void:
	super()
	if espiritual:
		# El reflejo vestido: la estatua reflejada y, en celeste tenue, dónde va cada prenda.
		_dibujar_de_cabeza(TEX_ESTATUA, transformaciones[0].aplicar(_vec(datos["estatua"])), 0.6)
		var destinos: Dictionary = datos["reflejo_vestido"]
		for nombre in destinos:
			_dibujar_de_cabeza(TEX_PRENDA[nombre], _vec(destinos[nombre]), 0.35)
	if en_paz:
		# Narciso descansa: donde estaba la estatua crece un narciso.
		draw_texture_rect(TEX_FLOR, _rect(_vec(datos["estatua"])), false)


# shortcut: voltea siempre en vertical, porque el estanque es un eje horizontal; con otro eje habría que voltear distinto.
## En un reflejo respecto a un eje horizontal la figura queda de cabeza, como en un estanque de verdad.
func _dibujar_de_cabeza(tex: Texture2D, c: Vector2i, alfa: float) -> void:
	draw_set_transform(_centro(c), 0.0, Vector2(1, -1))
	draw_texture_rect(_silueta(tex), Rect2(-Vector2.ONE * TAM * 0.45, Vector2.ONE * TAM * 0.9), false, Color(CELESTE, alfa))
	draw_set_transform(Vector2.ZERO)
