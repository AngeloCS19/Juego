class_name Sala
extends Node2D
## Una sala del templo, cargada desde un archivo JSON de res://salas/.
## Guarda el estado (jugador, piedras, plano activo), aplica las reglas y se dibuja.
##
## Letras del mapa:
##   #  muro      .  suelo     ~  agua      =  puente
##   v  vacío     E  salida

signal completada
signal plano_cambiado(espiritual: bool)
signal caida

const TAM := 48.0  # píxeles por casilla

# Colores provisionales: la paleta definitiva se decide cuando haya una base jugable.
const COLOR_CASILLA := {
	"#": Color(0.22, 0.2, 0.18),
	".": Color(0.55, 0.5, 0.4),
	"~": Color(0.2, 0.45, 0.7),
	"=": Color(0.45, 0.32, 0.2),
	"v": Color(0.04, 0.04, 0.06),
	"E": Color(0.85, 0.7, 0.3),
}
const COLOR_PIEDRA := Color(0.45, 0.7, 0.4)
const COLOR_PIEDRA_FIJA := Color(0.2, 0.4, 0.2)
const COLOR_JUGADOR := Color(0.95, 0.55, 0.2)
const CELESTE := Color(0.55, 0.85, 1.0)

var datos: Dictionary
var mapa: Array = []
var tamano: Vector2i
var transformacion: Transformacion
var jugador: Vector2i
var piedras: Array[Dictionary] = []  # cada una: {"pos": Vector2i, "fija": bool, "flota": bool, "marcada": bool}
var mirando := Vector2i.UP  # hacia dónde mira el jugador (la casilla que apuntan las habilidades)
var espiritual := false


func cargar(ruta: String) -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	mapa = datos["mapa"]
	tamano = Vector2i(mapa[0].length(), mapa.size())
	transformacion = Transformacion.desde_datos(datos["plano_espiritual"])
	reiniciar()


## Devuelve la sala a su estado inicial (el gong).
func reiniciar() -> void:
	jugador = _vec(datos["jugador"])
	mirando = Vector2i.UP
	piedras.clear()
	for p in datos.get("piedras", []):
		piedras.append({"pos": _vec(p["pos"]), "fija": p.get("fija", false), "flota": false, "marcada": false})
	if espiritual:
		espiritual = false
		plano_cambiado.emit(false)
	queue_redraw()


## Intenta mover al jugador una casilla en la dirección dada (en coordenadas del mundo).
func mover(dir: Vector2i) -> void:
	mirando = dir
	var destino := jugador + dir
	if not espiritual:
		var i := piedra_en(destino)
		if i >= 0 and not piedras[i]["flota"] and not _empujar(i, dir):
			return
	if transitable(destino):
		jugador = destino
		queue_redraw()
		if celda(jugador) == "E":
			completada.emit()


## Habilidad del jugador: pasar de un plano al otro.
## Volver al plano normal sobre el vacío o el agua es caer, y la sala se reinicia.
## Volver encima de una piedra no se permite.
func cambiar_plano() -> void:
	if espiritual and not _transitable_en_plano(jugador, false):
		if piedra_en(jugador) < 0:
			reiniciar()
			caida.emit()
		return
	espiritual = not espiritual
	plano_cambiado.emit(espiritual)
	queue_redraw()


## Marca (o desmarca) para la transformación la piedra que el jugador tiene enfrente.
## Solo las piedras marcadas aparecen transformadas en el plano espiritual.
func marcar_enfrente() -> bool:
	var i := piedra_en(jugador + mirando)
	if i < 0:
		return false
	piedras[i]["marcada"] = not piedras[i]["marcada"]
	queue_redraw()
	return true


func celda(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= tamano.x or c.y >= tamano.y:
		return "#"
	return mapa[c.y][c.x]


func piedra_en(c: Vector2i) -> int:
	for i in piedras.size():
		if piedras[i]["pos"] == c:
			return i
	return -1


## ¿Hay en esta casilla la imagen espiritual de alguna piedra?
func imagen_en(c: Vector2i) -> bool:
	for p in piedras:
		if p["marcada"] and transformacion.aplicar(p["pos"]) == c:
			return true
	return false


func transitable(c: Vector2i) -> bool:
	return _transitable_en_plano(c, espiritual)


func _transitable_en_plano(c: Vector2i, en_espiritual: bool) -> bool:
	var t := celda(c)
	if t == "#":
		return false
	if en_espiritual:
		# Se atraviesan objetos y agua; el vacío solo se cruza sobre un reflejo.
		return imagen_en(c) or t in [".", "=", "E", "~"]
	var i := piedra_en(c)
	if i >= 0:
		return piedras[i]["flota"]
	return t in [".", "=", "E"]


func _empujar(i: int, dir: Vector2i) -> bool:
	var p := piedras[i]
	if p["fija"]:
		return false
	var destino: Vector2i = p["pos"] + dir
	if piedra_en(destino) >= 0:
		return false
	match celda(destino):
		".":
			pass
		"~":
			p["flota"] = true  # una piedra en el agua queda flotando y se puede pisar
		_:
			return false
	p["pos"] = destino
	return true


func _vec(arr: Array) -> Vector2i:
	return Vector2i(int(arr[0]), int(arr[1]))


func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * TAM, Vector2(TAM, TAM))


func _centro(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TAM


func _draw() -> void:
	for y in tamano.y:
		for x in tamano.x:
			var c := Vector2i(x, y)
			if espiritual:
				_dibujar_casilla_espiritual(c)
			else:
				draw_rect(_rect(c), COLOR_CASILLA[celda(c)])
	if espiritual:
		transformacion.dibujar(self, TAM, tamano, CELESTE)
	for p in piedras:
		if espiritual:
			draw_circle(_centro(p["pos"]), TAM * 0.35, Color(CELESTE, 0.2))
			if p["marcada"]:
				draw_circle(_centro(transformacion.aplicar(p["pos"])), TAM * 0.4, Color(CELESTE, 0.85))
			continue
		if p["fija"]:
			_dibujar_piedra_fija(p["pos"])
		else:
			draw_circle(_centro(p["pos"]), TAM * (0.45 if p["flota"] else 0.38), COLOR_PIEDRA)
		if p["marcada"]:
			draw_circle(_centro(p["pos"]), TAM * 0.47, CELESTE, false, 3.0)
	var color_jugador := Color.WHITE if espiritual else COLOR_JUGADOR
	draw_circle(_centro(jugador), TAM * 0.3, color_jugador)
	# Un punto hacia donde mira, para saber qué piedra apuntan las habilidades.
	draw_circle(_centro(jugador) + Vector2(mirando) * TAM * 0.3, TAM * 0.08, Color.BLACK)


## Las piedras fijas son bloques cuadrados con raíces, para que no se confundan con las que se empujan.
func _dibujar_piedra_fija(c: Vector2i) -> void:
	var centro := _centro(c)
	for esquina in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		draw_line(centro, centro + esquina * TAM * 0.46, COLOR_PIEDRA_FIJA, 3.0)
	draw_rect(Rect2(centro - Vector2.ONE * TAM * 0.3, Vector2.ONE * TAM * 0.6), COLOR_PIEDRA_FIJA)


## En el plano espiritual el piso se desvanece y solo queda la cuadrícula.
func _dibujar_casilla_espiritual(c: Vector2i) -> void:
	var r := _rect(c)
	match celda(c):
		"#":
			draw_rect(r, Color(CELESTE, 0.08))
		"~":
			draw_rect(r, Color(CELESTE, 0.12))
		"E":
			draw_rect(r.grow(-4), Color(COLOR_CASILLA["E"], 0.6), false, 2.0)
	if celda(c) != "v":
		draw_rect(r, Color(CELESTE, 0.25), false, 1.0)
