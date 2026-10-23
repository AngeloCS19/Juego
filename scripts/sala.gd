class_name Sala
extends Node2D
## Una sala del templo, cargada desde un archivo JSON de res://salas/.
## Guarda el estado (jugador, piedras, plano activo), aplica las reglas y se dibuja.
##
## Letras del mapa:
##   #  muro      .  suelo     ~  agua      =  puente
##   v  vacío     E  salida    ^  lava (refleja como el río, pero nunca se sobrevuela)

signal completada
signal plano_cambiado(espiritual: bool)
signal caida
signal prenda_recogida(nombre: String)
signal derrota  # Narciso venció al jugador (jefe o huida): la fase o el tramo vuelve a empezar

const TAM := 48.0  # píxeles por casilla

# Sprites SVG de res://assets/sprites/ (ver docs/sprites.md).
const TEX_CASILLA := {
	"#": preload("res://assets/sprites/muro.svg"),
	".": preload("res://assets/sprites/piso.svg"),
	"~": preload("res://assets/sprites/agua.svg"),
	"=": preload("res://assets/sprites/puente.svg"),
	"v": preload("res://assets/sprites/vacio.svg"),
	"E": preload("res://assets/sprites/salida.svg"),
	"^": preload("res://assets/sprites/lava.svg"),
}
## Rocas que se mueven: irregulares, con variantes para que no todas se vean iguales.
const TEX_PIEDRAS := [
	preload("res://assets/sprites/piedra_1.svg"),
	preload("res://assets/sprites/piedra_2.svg"),
	preload("res://assets/sprites/piedra_3.svg"),
]
const TEX_PIEDRA_FIJA := preload("res://assets/sprites/piedra_fija.svg")
## Los tres personajes que se eligen en el menú inicial: niño, niña y espíritu.
const TEX_PERSONAJES := [
	preload("res://assets/sprites/jugador_nino.svg"),
	preload("res://assets/sprites/jugador_nina.svg"),
	preload("res://assets/sprites/jugador_espiritu.svg"),
]
const TEX_PASTO := preload("res://assets/sprites/pasto.svg")  # el piso de las salas con "exterior": true
const TEX_PRENDA := {
	"sandalias": preload("res://assets/sprites/prenda_sandalias.svg"),
	"cinto": preload("res://assets/sprites/prenda_cinto.svg"),
	"tunica": preload("res://assets/sprites/prenda_tunica.svg"),
	"corona": preload("res://assets/sprites/prenda_corona.svg"),
}
# shortcut: un solo anillo (reflexión); cuando haya más transformaciones, que cada una elija el suyo.
const TEX_ANILLO_REFLEJO := preload("res://assets/sprites/anillo_reflejo.svg")
# Solo para dibujar la salida fantasma del plano espiritual.
const COLOR_SALIDA := Color(0.85, 0.7, 0.3)
const CELESTE := Color(0.55, 0.85, 1.0)
const COLOR_LAVA := Color(0.95, 0.4, 0.2)

var datos: Dictionary
var mapa: Array = []
var tamano: Vector2i
var transformaciones: Array[Transformacion] = []  # una por eje: el río y, si hay, la lava
var jugador: Vector2i
var piedras: Array[Dictionary] = []  # cada una: {"pos": Vector2i, "fija": bool, "flota": bool, "marcada": bool, "variante": int}
var mirando := Vector2i.UP  # hacia dónde mira el jugador (la casilla que apuntan las habilidades)
var espiritual := false
var prenda_tomada := true  # false mientras la sala tenga una prenda de Narciso sin recoger (es opcional)
static var personaje := 0  # índice en TEX_PERSONAJES; static: lo comparten todas las salas
var tiempo_real := false  # dificultad difícil en el jefe: los turnos pasan solos
var _reloj: Timer
static var _siluetas := {}  # sprite -> su silueta blanca, se calcula una vez


## Crea la sala que describe el archivo. El "tipo" del JSON elige la clase:
## sin tipo es una sala de puzzle; "jefe", "huida" y "altar" son las salas de Narciso.
static func desde_archivo(ruta: String) -> Sala:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	var nueva: Sala
	match d.get("tipo", ""):
		"jefe":
			nueva = SalaJefe.new()
		"huida":
			nueva = SalaHuida.new()
		"altar":
			nueva = SalaAltar.new()
		_:
			nueva = Sala.new()
	nueva.cargar(ruta)
	return nueva


func cargar(ruta: String) -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	_preparar()


## Lee de "datos" el mapa y los ejes, y deja la sala en su estado inicial.
func _preparar() -> void:
	mapa = datos["mapa"]
	tamano = Vector2i(mapa[0].length(), mapa.size())
	# "plano_espiritual" es una transformación o una lista de ellas (una por eje).
	var plano = datos["plano_espiritual"]
	transformaciones.clear()
	for t in (plano if plano is Array else [plano]):
		transformaciones.append(Transformacion.desde_datos(t))
	reiniciar()


## Devuelve la sala a su estado inicial (el gong).
func reiniciar() -> void:
	jugador = _vec(datos["jugador"])
	mirando = Vector2i.UP
	prenda_tomada = not datos.has("prenda")
	piedras.clear()
	for p in datos.get("piedras", []):
		piedras.append({"pos": _vec(p["pos"]), "fija": p.get("fija", false), "flota": false, "marcada": false, "variante": piedras.size()})
	if espiritual:
		espiritual = false
		plano_cambiado.emit(false)
	queue_redraw()


## Gira al jugador hacia la dirección dada (en coordenadas del mundo) y avanza una casilla
## si se puede. Contra una piedra solo gira: para moverla se usa empujar_enfrente().
func mover(dir: Vector2i) -> void:
	mirando = dir
	queue_redraw()
	if transitable(jugador + dir):
		_avanzar(dir)
	_accion()


## ¿Hay enfrente una piedra que se pueda intentar empujar?
func hay_empujable_enfrente() -> bool:
	var i := piedra_en(jugador + mirando)
	return not espiritual and i >= 0 and not piedras[i]["fija"] and not piedras[i]["flota"]


## Empuja la piedra que el jugador mira y avanza detrás de ella.
func empujar_enfrente() -> bool:
	if not hay_empujable_enfrente() or not _empujar(piedra_en(jugador + mirando), mirando):
		return false
	_avanzar(mirando)
	_accion()
	return true


func _avanzar(dir: Vector2i) -> void:
	jugador += dir
	queue_redraw()
	# Las prendas son de un espíritu: solo se ven y se recogen en el plano espiritual.
	if espiritual and not prenda_tomada and jugador == _vec(datos["prenda"]["pos"]):
		prenda_tomada = true
		prenda_recogida.emit(datos["prenda"]["nombre"])
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
	_accion()


## Marca (o desmarca) para la transformación la piedra que el jugador tiene enfrente.
## Solo las piedras marcadas aparecen transformadas en el plano espiritual.
func marcar_enfrente() -> bool:
	var i := piedra_en(jugador + mirando)
	if i < 0:
		return false
	piedras[i]["marcada"] = not piedras[i]["marcada"]
	queue_redraw()
	_accion()
	return true


## Cada acción del jugador cuenta como un turno, salvo en tiempo real, donde los turnos los marca un reloj.
## Las salas de puzzle no hacen nada en su turno; el jefe sí.
func _accion() -> void:
	if not tiempo_real:
		_turno()


func _turno() -> void:
	pass


## Dificultad difícil: el mundo avanza un turno cada "intervalo" segundos, aunque el jugador no se mueva.
func usar_tiempo_real(activo: bool, intervalo: float) -> void:
	tiempo_real = activo
	if _reloj == null:
		_reloj = Timer.new()
		_reloj.timeout.connect(_turno)
		add_child(_reloj)
	_reloj.wait_time = intervalo
	if activo:
		_reloj.start()
	else:
		_reloj.stop()


## Texto extra para la interfaz (corazones, vida del jefe...). Las salas de puzzle no tienen.
func estado() -> String:
	return ""


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
		if p["marcada"]:
			for t in transformaciones:
				if t.aplicar(p["pos"]) == c:
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
		# La lava nunca: solo se cruza en el plano normal, sobre una piedra hundida en ella.
		return t != "^" and (imagen_en(c) or t in [".", "=", "E", "~"])
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
		"~", "^":
			p["flota"] = true  # una piedra en el agua o la lava queda flotando y se puede pisar
		_:
			return false
	p["pos"] = destino
	return true


## Copia del sprite con todos los píxeles blancos (conserva la forma). Se tiñe con el color de dibujo:
## modulate multiplica, así que sobre un sprite verde el celeste no se vería celeste.
func _silueta(tex: Texture2D) -> Texture2D:
	if not tex in _siluetas:
		var img := tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y, Color(1, 1, 1, img.get_pixel(x, y).a))
		_siluetas[tex] = ImageTexture.create_from_image(img)
	return _siluetas[tex]


func _vec(arr: Array) -> Vector2i:
	return Vector2i(int(arr[0]), int(arr[1]))


func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * TAM, Vector2(TAM, TAM))


func _centro(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TAM


## Sprite de una piedra. El altar lo cambia para dibujar la estatua y las prendas.
func _tex_piedra(p: Dictionary) -> Texture2D:
	return TEX_PIEDRA_FIJA if p["fija"] else TEX_PIEDRAS[p.get("variante", 0) % TEX_PIEDRAS.size()]


func _draw() -> void:
	for y in tamano.y:
		for x in tamano.x:
			var c := Vector2i(x, y)
			if espiritual:
				_dibujar_casilla_espiritual(c)
			else:
				var piso: Texture2D = TEX_PASTO if datos.get("exterior", false) else TEX_CASILLA["."]
				if celda(c) == "E":
					draw_texture_rect(piso, _rect(c), false)  # el espejo de la salida es redondo: debajo va el piso
				var tex: Texture2D = piso if celda(c) == "." else TEX_CASILLA[celda(c)]
				draw_texture_rect(tex, _rect(c), false)
	if espiritual:
		for t in transformaciones:
			t.dibujar(self, TAM, tamano, CELESTE)
	for p in piedras:
		if espiritual:
			# Los objetos pasan a ser translúcidos y celestes: la silueta blanca del sprite, teñida.
			var r_fantasma := Rect2(_centro(p["pos"]) - Vector2.ONE * TAM * 0.5, Vector2.ONE * TAM)
			draw_texture_rect(_silueta(_tex_piedra(p)), r_fantasma, false, Color(CELESTE, 0.3))
			if p["marcada"]:
				for t in transformaciones:  # un reflejo por cada eje
					var r_imagen := Rect2(_centro(t.aplicar(p["pos"])) - Vector2.ONE * TAM * 0.5, Vector2.ONE * TAM)
					draw_texture_rect(_silueta(_tex_piedra(p)), r_imagen, false, Color(CELESTE, 0.85))
			continue
		var escala := 1.18 if p["flota"] else 1.0  # una piedra en el agua se ve un poco más grande
		var lado := TAM * escala
		var r := Rect2(_centro(p["pos"]) - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
		# Hundida en la lava se tiñe de rojo, como si se mezclara con ella.
		var hundida: bool = p["flota"] and celda(p["pos"]) == "^"
		draw_texture_rect(_tex_piedra(p), r, false, Color(1, 0.55, 0.4) if hundida else Color.WHITE)
		if p["marcada"]:
			draw_texture_rect(TEX_ANILLO_REFLEJO, r, false)
	if espiritual and not prenda_tomada:
		draw_texture_rect(TEX_PRENDA[datos["prenda"]["nombre"]], _rect(_vec(datos["prenda"]["pos"])).grow(-4), false)
	# El sprite del jugador apunta hacia arriba: se gira hacia donde mira.
	draw_set_transform(_centro(jugador), Vector2(mirando).angle() + PI / 2)
	var lado_j := TAM * 0.9
	var tex_jugador: Texture2D = TEX_PERSONAJES[personaje]
	if espiritual:
		tex_jugador = _silueta(tex_jugador)
	draw_texture_rect(tex_jugador, Rect2(-Vector2.ONE * lado_j * 0.5, Vector2.ONE * lado_j), false)
	draw_set_transform(Vector2.ZERO)


## En el plano espiritual el piso se desvanece y solo queda la cuadrícula.
func _dibujar_casilla_espiritual(c: Vector2i) -> void:
	var r := _rect(c)
	match celda(c):
		"#":
			draw_rect(r, Color(CELESTE, 0.08))
		"~":
			draw_rect(r, Color(CELESTE, 0.12))
		"^":
			draw_rect(r, Color(COLOR_LAVA, 0.25))
		"E":
			draw_arc(_centro(c), TAM * 0.4, 0.0, TAU, 32, Color(COLOR_SALIDA, 0.6), 2.0)
	if celda(c) != "v":
		draw_rect(r, Color(CELESTE, 0.25), false, 1.0)
