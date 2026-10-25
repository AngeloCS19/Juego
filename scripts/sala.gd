class_name Sala
extends Node2D
## Una sala del templo, cargada desde un archivo JSON de res://salas/.
## Guarda el estado (jugador, piedras, plano activo), aplica las reglas y se dibuja.
##
## Letras del mapa:
##   #  muro      .  suelo     ~  agua      =  puente
##   v  vacío     E  salida    ^  lava (refleja como el río, pero nunca se sobrevuela)
##
## Con "salida_fija": true, la E va en el muro de afuera: es una puerta, y el espejo queda fijo
## arriba de la pantalla (lo dibuja main.gd). La puerta solo abre si la cámara la deja frente al espejo.

signal completada
signal plano_cambiado(espiritual: bool)
signal caida
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
const TEX_ESTILO := {  # "estilo" de la sala: cada templo cambia su muro y su piso
	"tutorial": {  # el espejo es de Narciso: fuera de su templo se sale por una puerta de madera
		"#": preload("res://assets/sprites/muro_tutorial.svg"),
		".": preload("res://assets/sprites/piso_tutorial.svg"),
		"E": preload("res://assets/sprites/puerta_madera.svg"),
	},
}
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
const COLOR_VELA := Color(1.0, 0.75, 0.35)
# Animaciones: solo cambian el dibujo. Las reglas ya cambiaron al instante, así las pruebas no esperan.
const DURACION_PASO := 0.12  # segundos que tarda en verse un paso
const DURACION_EMPUJE := 0.3  # un empujón es más lento: dura lo mismo que el sonido de la piedra que se arrastra
const DURACION_REFLEJO := 0.6  # lo que tarda el reflejo en viajar al otro lado del eje: se ve, es lo que se aprende
const DURACION_CAIDA := 0.6  # main.gd espera esto antes de abrir la ventana de derrota
const DURACION_SALIDA := 0.6  # el personaje entra al espejo; main.gd espera esto antes de la cortina
const DURACION_PRENDA := 1.0  # la prenda sube sobre la cabeza y se desvanece
const DURACION_MANCHA := 0.5  # la mancha de tinta que se expande al Traspasar
const DURACION_HUMO := 1.2  # el humo de la vela que se acaba de apagar

var datos: Dictionary
var mapa: Array = []
var tamano: Vector2i
var transformaciones: Array[Transformacion] = []  # una por eje: el río y, si hay, la lava
var jugador: Vector2i
var piedras: Array[Dictionary] = []  # cada una: {"pos": Vector2i, "fija": bool, "flota": bool, "marcada": bool, "variante": int}
var salida: Vector2i  # dónde está la E del mapa
var giro := 0  # cuartos de vuelta de la cámara; main.gd lo copia aquí para saber si la puerta calza
var mirando := Vector2i.UP  # hacia dónde mira el jugador (la casilla que apuntan las habilidades)
var espiritual := false
var tutorial_piedra := Vector2i(-1, -1)  # piedra que brilla para indicar dónde usar Reflejo (tutorial); (-1, -1): ninguna
var prenda_tomada := true  # false mientras la sala tenga una prenda de Narciso sin recoger (es opcional)
static var personaje := 0  # índice en TEX_PERSONAJES; static: lo comparten todas las salas
var traspasos := 0  # veces que entró al plano espiritual; reiniciar no lo borra: las velas no se vuelven a encender
var tiempo := 0.0  # segundos jugados en la sala, con reinicios (la pausa no cuenta)
var tiempo_real := false  # jefe y huida: los turnos los marca un reloj (las pruebas juegan por turnos)
var _reloj: Timer
var _t := 0.0  # reloj de las animaciones
var _vis := {}  # posiciones dibujadas (en píxeles); siguen a las reales con suavidad (ver _seguir)
var _angulo := 0.0  # ángulo dibujado del jugador
var _t_plano := 0.0  # tiempo desde que se entró al plano espiritual
var _duracion_jugador := DURACION_PASO  # DURACION_EMPUJE mientras camina detrás de una piedra
var _caida_t := DURACION_CAIDA  # tiempo desde la última caída (DURACION_CAIDA o más: no está cayendo)
var _caida_en := Vector2.ZERO
var _salida_t := DURACION_SALIDA  # tiempo desde que llegó al espejo (DURACION_SALIDA o más: no está entrando)
var _prenda_t := DURACION_PRENDA
var _prenda_nombre := ""
var _mancha_t := DURACION_MANCHA
var _humo_t := DURACION_HUMO
var _velas_en := []  # cada vela: [casilla del muro, hacia dónde da al interior]
var _mancha_en := Vector2.ZERO
var _mancha_onda: Array[Vector3] = []  # la forma de esta mancha: (amplitud, ondas por vuelta, desfase)
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
	for y in tamano.y:
		if "E" in mapa[y]:
			salida = Vector2i(mapa[y].find("E"), y)
	# "plano_espiritual" es una transformación o una lista de ellas (una por eje).
	var plano = datos["plano_espiritual"]
	transformaciones.clear()
	for t in (plano if plano is Array else [plano]):
		transformaciones.append(Transformacion.desde_datos(t))
	_poner_velas()
	reiniciar()


## Las velas iluminan la sala desde los muros de los lados: mitad a la izquierda y mitad a la
## derecha, repartidas a lo alto, pegadas a la cara del muro que da al interior.
func _poner_velas() -> void:
	_velas_en.clear()
	var lados := [_muros_de_lado(range(tamano.x), Vector2i.RIGHT), _muros_de_lado(range(tamano.x - 1, -1, -1), Vector2i.LEFT)]
	var n: int = datos.get("velas", 0)
	var izq := mini(ceili(n / 2.0), lados[0].size())
	var cuantas := [izq, mini(n - izq, lados[1].size())]
	for i in maxi(cuantas[0], cuantas[1]):  # alternadas: las que se apagan van de un lado y del otro
		for l in 2:
			if i < cuantas[l]:
				_velas_en.append(lados[l][int((i + 0.5) * lados[l].size() / cuantas[l])])  # repartidas a lo alto


## Por cada fila, el primer muro (recorriendo "columnas") cuya cara "dentro" da al interior de la sala.
func _muros_de_lado(columnas: Array, dentro: Vector2i) -> Array:
	var muros := []
	for y in tamano.y:
		for x in columnas:
			var c := Vector2i(x, y)
			if celda(c) != "#":
				break  # en esta fila el borde no es muro (un río que sale de la sala): no hay vela
			if celda(c + dentro) != "#":
				if celda(c + dentro) == ".":  # solo sobre piso: junto al agua o al vacío no se pone
					muros.append([c, dentro])
				break
	return muros


## Velas que siguen encendidas: cada vez que se entra al plano espiritual se apaga una.
func velas_encendidas() -> int:
	return maxi(0, datos.get("velas", 0) - traspasos)


## Devuelve la sala a su estado inicial (el gong).
func reiniciar() -> void:
	jugador = _vec(datos["jugador"])
	mirando = Vector2i.UP
	prenda_tomada = not datos.has("prenda")
	_salida_t = DURACION_SALIDA
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
	if cayendo():
		return
	mirando = dir
	queue_redraw()
	if transitable(jugador + dir):
		_duracion_jugador = DURACION_PASO
		_avanzar(dir)
	_accion()


## ¿Hay enfrente una piedra que se pueda intentar empujar?
func hay_empujable_enfrente() -> bool:
	var i := piedra_en(jugador + mirando)
	return not espiritual and not cayendo() and i >= 0 and not piedras[i]["fija"] and not piedras[i]["flota"]


## Empuja la piedra que el jugador mira y avanza detrás de ella.
func empujar_enfrente() -> bool:
	if not hay_empujable_enfrente() or not _empujar(piedra_en(jugador + mirando), mirando):
		return false
	_duracion_jugador = DURACION_EMPUJE  # el jugador avanza al paso de la piedra
	Sonido.tocar("empujar")
	_avanzar(mirando, false)
	_accion()
	return true


## "paso": si suena el paso (al empujar suena la piedra).
func _avanzar(dir: Vector2i, paso := true) -> void:
	jugador += dir
	queue_redraw()
	if paso:
		Sonido.tocar(_sonido_paso(), 0.0, randf_range(0.9, 1.1))  # cada paso un poco distinto
	# Las prendas son de un espíritu: solo se ven y se recogen en el plano espiritual.
	if espiritual and not prenda_tomada and jugador == _vec(datos["prenda"]["pos"]):
		prenda_tomada = true
		_prenda_nombre = datos["prenda"]["nombre"]
		_prenda_t = 0.0
		Sonido.tocar("prenda")
	if celda(jugador) == "E":
		_salida_t = 0.0  # main.gd espera DURACION_SALIDA para pasar de sala
		if datos.get("estilo", "") != "tutorial":  # en el tutorial suena la puerta al cerrarse la cortina
			Sonido.tocar("salida")
		completada.emit()


## El paso suena según el piso: madera en el puente, pasto afuera, arenisca en el templo.
## Un templo nuevo con otro piso solo agrega aquí su caso y su archivo paso_*.ogg.
func _sonido_paso() -> String:
	if celda(jugador) == "=":
		return "paso_madera"
	return "paso_pasto" if datos.get("exterior", false) else "paso_arenisca"


## Habilidad del jugador: pasar de un plano al otro.
## Volver al plano normal sobre el vacío o el agua es caer, y la sala se reinicia.
## Volver encima de una piedra no se permite.
func cambiar_plano() -> void:
	if espiritual and not _transitable_en_plano(jugador, false):
		if piedra_en(jugador) < 0:
			_caida_en = _visto("jugador", jugador)
			_caida_t = 0.0
			Sonido.tocar("caer")
			reiniciar()
			caida.emit()
		return
	espiritual = not espiritual
	if espiritual:
		traspasos += 1
		_humo_t = 0.0
	Sonido.tocar("traspasar" if espiritual else "volver")
	_t_plano = 0.0  # al entrar, los reflejos viajan desde su piedra
	_nueva_mancha()
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
	# Marcar: una nota cristalina. Desmarcar: la misma, más baja y suave.
	Sonido.tocar("reflejo", 0.0 if piedras[i]["marcada"] else -8.0, 1.0 if piedras[i]["marcada"] else 0.84)
	piedras[i]["t_marca"] = 0.0  # el anillo aparece con un salto y el reflejo viaja
	queue_redraw()
	_accion()
	return true


## Mientras se ve la caída o la entrada al espejo el jugador no puede actuar.
## Fuera del árbol de escenas (las pruebas) nunca se espera.
func cayendo() -> bool:
	return is_inside_tree() and (_caida_t < DURACION_CAIDA or _salida_t < DURACION_SALIDA)


func _process(delta: float) -> void:
	_t += delta
	_t_plano += delta
	_caida_t += delta
	_salida_t += delta
	_prenda_t += delta
	_mancha_t += delta
	_humo_t += delta
	tiempo += delta
	_seguir("jugador", _centro(jugador), delta, _duracion_jugador)
	_angulo = lerp_angle(_angulo, Vector2(mirando).angle() + PI / 2, minf(1.0, delta * 20.0))
	for p in piedras:
		var destino := _centro(p["pos"])
		var v: Vector2 = p.get("vis", destino)
		p["vis"] = destino if v.distance_to(destino) > TAM * 2.5 else v.move_toward(destino, TAM * delta / DURACION_EMPUJE)
		p["t_marca"] = p.get("t_marca", 1.0) + delta
	queue_redraw()


## Acerca la posición dibujada "clave" a la real, a una casilla cada "duracion" segundos.
## Si está lejos (la sala se reinició), salta de una vez.
func _seguir(clave: String, destino: Vector2, delta: float, duracion := DURACION_PASO) -> void:
	var v: Vector2 = _vis.get(clave, destino)
	_vis[clave] = destino if v.distance_to(destino) > TAM * 2.5 else v.move_toward(destino, TAM * delta / duracion)


func _visto(clave: String, real: Vector2i) -> Vector2:
	return _vis.get(clave, _centro(real))


## Dónde dibujar a Narciso (jefe y huida): su posición suave, subiendo y bajando como si flotara.
## "prisa" acelera el vaivén: más enojado, más rápido.
func _flotar(clave: String, real: Vector2i, prisa: float) -> Vector2:
	return _visto(clave, real) + Vector2(0, sin(_t * prisa * 2.0) * 3.0)


## Dibuja a Narciso: un aura del color de su ánimo, su sprite y, si acaba de recibir un golpe,
## un destello blanco encima ("destello" de 0 a 1). "alfa" lo vuelve translúcido en el plano normal.
func _dibujar_narciso(centro: Vector2, aura: Color, alfa: float, destello := 0.0) -> void:
	draw_circle(centro, TAM * 0.6, Color(aura, 0.3 * alfa))
	var r := Rect2(centro - Vector2.ONE * (TAM * 0.5 + 4), Vector2.ONE * (TAM + 8))
	draw_texture_rect(SalaJefe.TEX_NARCISO, r, false, Color(Color.WHITE.lerp(aura, 0.25), alfa))
	if destello > 0.0:
		draw_texture_rect(_silueta(SalaJefe.TEX_NARCISO), r, false, Color(1, 1, 1, destello * alfa))


## Cada acción del jugador cuenta como un turno, salvo en tiempo real, donde los turnos los marca un reloj.
## Las salas de puzzle no hacen nada en su turno; el jefe sí.
func _accion() -> void:
	if not tiempo_real:
		_turno()


func _turno() -> void:
	pass


## Jefe y huida: el mundo avanza un turno cada "intervalo" segundos, aunque el jugador no se mueva.
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


## ¿La puerta de una sala con "salida_fija" mira hacia arriba en la pantalla? Las demás salas siempre abren.
func puerta_abierta() -> bool:
	if not datos.get("salida_fija", false):
		return true
	var afuera := Vector2i.UP if salida.y == 0 else Vector2i.DOWN if salida.y == tamano.y - 1 else Vector2i.LEFT if salida.x == 0 else Vector2i.RIGHT
	return Vector2i(Vector2(afuera).rotated(giro * PI / 2).round()) == Vector2i.UP


func transitable(c: Vector2i) -> bool:
	return _transitable_en_plano(c, espiritual)


func _transitable_en_plano(c: Vector2i, en_espiritual: bool) -> bool:
	var t := celda(c)
	if t == "#" or (t == "E" and not puerta_abierta()):
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
			if celda(destino) == "^":
				Sonido.tocar("lava")
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
				var casillas: Dictionary = TEX_ESTILO.get(datos.get("estilo", ""), TEX_CASILLA)
				var piso: Texture2D = TEX_PASTO if datos.get("exterior", false) else casillas["."]
				if celda(c) == "E":
					draw_texture_rect(piso, _rect(c), false)  # el espejo de la salida es redondo: debajo va el piso
				var puerta: bool = celda(c) == "E" and datos.get("salida_fija", false)  # el espejo está afuera: aquí solo hay piso
				var tex: Texture2D = piso if celda(c) == "." or puerta else casillas.get(celda(c), TEX_CASILLA[celda(c)])
				draw_texture_rect(tex, _rect(c), false)
				if puerta:
					draw_rect(_rect(c), Color(COLOR_SALIDA, 0.3) if puerta_abierta() else Color(0, 0, 0, 0.55))
				if celda(c) == "~":
					_animar_agua(c)
				elif celda(c) == "^":
					_animar_lava(c)
	if espiritual:
		for t in transformaciones:
			t.dibujar(self, TAM, tamano, CELESTE)
	_dibujar_velas()
	for p in piedras:
		var centro: Vector2 = p.get("vis", _centro(p["pos"]))
		if espiritual:
			# Los objetos pasan a ser translúcidos y celestes: la silueta blanca del sprite, teñida.
			var r_fantasma := Rect2(centro - Vector2.ONE * TAM * 0.5, Vector2.ONE * TAM)
			draw_texture_rect(_silueta(_tex_piedra(p)), r_fantasma, false, Color(CELESTE, 0.3))
			if p["marcada"]:
				# El reflejo viaja en línea recta desde la piedra, cruzando el eje en ángulo recto.
				# Al traspasar, el viaje empieza cuando la mancha ya casi pasó, para que se vea bien.
				var viaje := minf(_t_plano - DURACION_MANCHA * 0.8, p.get("t_marca", 9.0))
				var k := ease(clampf(viaje / DURACION_REFLEJO, 0.0, 1.0), 0.4)  # sale rápido y frena al llegar
				for t in transformaciones:  # un reflejo por cada eje
					var imagen := _centro(t.aplicar(p["pos"]))
					var r_imagen := Rect2(centro.lerp(imagen, k) - Vector2.ONE * TAM * 0.5, Vector2.ONE * TAM)
					draw_texture_rect(_silueta(_tex_piedra(p)), r_imagen, false, Color(CELESTE, 0.3 + 0.55 * k))
			continue
		var escala := 1.18 if p["flota"] else 1.0  # una piedra en el agua se ve un poco más grande
		var lado := TAM * escala
		var r := Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
		# Hundida en la lava se tiñe de rojo, como si se mezclara con ella.
		var hundida: bool = p["flota"] and celda(p["pos"]) == "^"
		draw_texture_rect(_tex_piedra(p), r, false, Color(1, 0.55, 0.4) if hundida else Color.WHITE)
		if p["marcada"]:
			var salto := 1.0 + 0.35 * maxf(0.0, 1.0 - p.get("t_marca", 1.0) / 0.25)  # aparece grande y se asienta
			draw_texture_rect(TEX_ANILLO_REFLEJO, Rect2(centro - r.size * salto * 0.5, r.size * salto), false)
	if not espiritual and tutorial_piedra.x >= 0:
		var i := piedra_en(tutorial_piedra)
		if i >= 0 and not piedras[i]["marcada"]:
			var k := 0.5 + 0.5 * sin(_t * TAU / 1.1)  # pulso de tamaño y brillo
			var c: Vector2 = piedras[i].get("vis", _centro(tutorial_piedra))
			draw_circle(c, TAM * (0.55 + 0.2 * k), Color(1, 0.85, 0.4, 0.15 + 0.25 * k))
			draw_arc(c, TAM * (0.58 + 0.2 * k), 0, TAU, 40, Color(1, 0.88, 0.5, 0.5 + 0.5 * k), 3.0)
	if espiritual and not prenda_tomada:
		draw_texture_rect(TEX_PRENDA[datos["prenda"]["nombre"]], _rect(_vec(datos["prenda"]["pos"])).grow(-4), false)
	var tex_jugador: Texture2D = TEX_PERSONAJES[personaje]
	if _caida_t < DURACION_CAIDA:
		# Cae girando y achicándose donde volvió al plano normal; la sala ya se reinició debajo.
		var k := _caida_t / DURACION_CAIDA
		draw_set_transform(_caida_en, _angulo + k * TAU, Vector2.ONE * (1.0 - k))
		draw_texture_rect(tex_jugador, Rect2(-Vector2.ONE * TAM * 0.45, Vector2.ONE * TAM * 0.9), false, Color(1, 1, 1, 1.0 - k))
		draw_set_transform(Vector2.ZERO)
		return
	# El sprite del jugador apunta hacia arriba: se gira hacia donde mira.
	# Al caminar da un saltito: crece un poco a mitad de paso.
	var pos := _visto("jugador", jugador)
	var entrada := _salida_t / DURACION_SALIDA
	if entrada < 1.0:
		_dibujar_entrada(pos, entrada, _silueta(tex_jugador) if espiritual else tex_jugador)
		return
	var a_mitad := pos.distance_to(_centro(jugador)) / TAM
	draw_set_transform(pos, _angulo, Vector2.ONE * (1.0 + 0.1 * sin(clampf(a_mitad, 0.0, 1.0) * PI)))
	var lado_j := TAM * 0.9
	if espiritual:
		tex_jugador = _silueta(tex_jugador)
	draw_texture_rect(tex_jugador, Rect2(-Vector2.ONE * lado_j * 0.5, Vector2.ONE * lado_j), false)
	draw_set_transform(Vector2.ZERO)
	_dibujar_prenda(pos)
	_dibujar_mancha()


## Entrar al espejo: se desliza al centro, se achica y se desvanece con un brillo del cristal.
func _dibujar_entrada(pos: Vector2, k: float, tex: Texture2D) -> void:
	var centro := _centro(jugador)
	var brillo := sin(k * PI)
	draw_circle(centro, TAM * (0.3 + 0.35 * brillo), Color(1.0, 0.95, 0.75, 0.55 * brillo))
	draw_arc(centro, TAM * (0.2 + 0.4 * k), 0.0, TAU, 32, Color(1.0, 1.0, 0.9, 0.8 * (1.0 - k)), 2.5)
	draw_set_transform(pos.lerp(centro, minf(1.0, k * 3.0)), _angulo, Vector2.ONE * (1.0 - ease(k, 2.0) * 0.9))
	draw_texture_rect(tex, Rect2(-Vector2.ONE * TAM * 0.45, Vector2.ONE * TAM * 0.9), false, Color(1, 1, 1, 1.0 - smoothstep(0.4, 1.0, k)))
	draw_set_transform(Vector2.ZERO)


## Al recoger una prenda: aparece sobre la cabeza, flota hacia arriba, crece, brilla y se desvanece.
func _dibujar_prenda(pos: Vector2) -> void:
	if _prenda_t >= DURACION_PRENDA:
		return
	var k := _prenda_t / DURACION_PRENDA
	var centro := pos + Vector2(0, -TAM * (0.8 + 0.7 * ease(k, 0.5)))
	var lado := TAM * (0.6 + 0.4 * ease(k, 0.5))
	var alfa := 1.0 - smoothstep(0.6, 1.0, k)
	var r := Rect2(centro - Vector2.ONE * lado * 0.5, Vector2.ONE * lado)
	draw_circle(centro, lado * 0.7, Color(1.0, 0.9, 0.5, 0.35 * sin(k * PI) * alfa))
	draw_texture_rect(TEX_PRENDA[_prenda_nombre], r, false, Color(1, 1, 1, alfa))
	var destello := maxf(0.0, 1.0 - absf(k - 0.4) / 0.2)  # un brillo breve a mitad del vuelo
	if destello > 0.0:
		draw_texture_rect(_silueta(TEX_PRENDA[_prenda_nombre]), r, false, Color(1, 1, 1, 0.8 * destello))


## El agua se mueve sin dejar de ser lisa: dos brillos tenues que ondulan despacio, cada casilla
## con su propia fase (su posición), para que el río no parpadee todo a la vez.
func _animar_agua(c: Vector2i) -> void:
	var o := _rect(c).position
	var fase := c.x * 1.3 + c.y * 0.7
	for i in 2:
		var y := TAM * (0.35 + i * 0.35) + sin(_t * 1.2 + fase + i) * TAM * 0.06
		var alfa := 0.12 + 0.08 * sin(_t * 1.5 + fase + i * 2.0)
		draw_line(o + Vector2(TAM * 0.18, y), o + Vector2(TAM * 0.82, y), Color(0.81, 0.92, 0.95, alfa), 2.5)


## Lava espesa: en cada casilla hay dos "puestos" de burbuja. Cada puesto repite un ciclo lento (2 a 4 s):
## la burbuja crece despacio en un punto de la casilla y revienta con un anillo. En cada ciclo nuevo
## el punto cambia; sale de la casilla, el puesto y el número de ciclo (no hay azar real, así no parpadea).
func _animar_lava(c: Vector2i) -> void:
	var o := _rect(c).position
	for i in 2:
		var periodo := 2.0 + 2.0 * _azar(c, i, -1, 0)
		var t := _t / periodo + _azar(c, i, -1, 1)  # el desfase es propio de cada casilla y puesto
		var ciclo := floori(t)
		var k := t - ciclo  # de 0 a 1 dentro del ciclo
		var p := o + Vector2(_azar(c, i, ciclo, 2), _azar(c, i, ciclo, 3)) * TAM * 0.5 + Vector2.ONE * TAM * 0.25
		var maximo := TAM * (0.09 + 0.07 * _azar(c, i, ciclo, 4))
		if k < 0.8:
			var g := ease(k / 0.8, 0.6)  # se infla despacio
			draw_circle(p, maximo * g, Color(0.99, 0.62, 0.28, 0.45))
			draw_arc(p, maximo * g, 0.0, TAU, 16, Color(1.0, 0.83, 0.42, 0.75), 1.5)
			draw_circle(p + Vector2(-0.3, -0.3) * maximo * g, maximo * g * 0.25, Color(1.0, 0.9, 0.6, 0.6))
		else:
			var r := (k - 0.8) / 0.2  # revienta: un anillo que se abre y se apaga
			draw_arc(p, maximo * (1.0 + 0.8 * r), 0.0, TAU, 16, Color(1.0, 0.83, 0.42, 0.7 * (1.0 - r)), 1.5)


## Número pseudoaleatorio de 0 a 1 que depende solo de la casilla, el puesto, el ciclo y un "canal".
func _azar(c: Vector2i, puesto: int, ciclo: int, canal: int) -> float:
	return fposmod(sin(c.x * 12.9898 + c.y * 78.233 + puesto * 37.719 + ciclo * 4.581 + canal * 19.19) * 43758.5453, 1.0)


## Al Traspasar, una mancha de tinta del color del plano nuevo se expande desde el jugador.
## Su borde es una suma de ondas con amplitudes y desfases al azar, así nunca sale igual.
func _nueva_mancha() -> void:
	_mancha_t = 0.0
	_mancha_en = _visto("jugador", jugador)
	_mancha_onda.clear()
	for ondas in [2, 3, 5, 7]:
		_mancha_onda.append(Vector3(randf_range(0.03, 0.13), ondas, randf() * TAU))


func _dibujar_mancha() -> void:
	if _mancha_t >= DURACION_MANCHA:
		return
	var k := _mancha_t / DURACION_MANCHA
	# Crece hasta cubrir toda la pantalla: la esquina más lejana, dividida entre el radio más chico
	# que puede tener la mancha por sus ondas (si no, quedarían huecos en el borde).
	var a_pantalla := get_global_transform_with_canvas().affine_inverse()
	var lejos := 0.0
	for esquina in [Vector2.ZERO, Vector2(get_viewport_rect().size.x, 0), Vector2(0, get_viewport_rect().size.y), get_viewport_rect().size]:
		lejos = maxf(lejos, _mancha_en.distance_to(a_pantalla * esquina))
	var minimo := 1.0
	for o in _mancha_onda:
		minimo -= o.x
	var radio := ease(minf(k / 0.8, 1.0), 0.8) * lejos / minimo  # llega a la esquina más lejana al 80 % del tiempo
	var color := Color(0.35, 0.65, 1.0) if espiritual else Color(0.95, 0.8, 0.55)
	var borde := PackedVector2Array()
	for i in 64:
		var angulo := TAU * i / 64
		var r := 1.0
		for o in _mancha_onda:
			r += o.x * sin(o.y * angulo + o.z + _t * 4.0)  # el borde se sigue moviendo, como tinta en agua
		borde.append(_mancha_en + Vector2.from_angle(angulo) * radio * r)
	var alfa := 1.0 - smoothstep(0.45, 0.85, k)  # se desvanece mientras llega al borde: casi no tapa la pantalla
	draw_colored_polygon(borde, Color(color, 0.55 * alfa))
	borde.append(borde[0])
	draw_polyline(borde, Color(color.lightened(0.5), 0.9 * alfa), 5.0)


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
			draw_arc(_centro(c), TAM * 0.32, 0.0, TAU, 32, Color(COLOR_SALIDA, 0.6), 2.0)
	if celda(c) != "v":
		draw_rect(r, Color(CELESTE, 0.25), false, 1.0)


## Cada vela: un soporte de hierro en la cara del muro, la vela vista desde arriba y una llama que
## tiembla hacia el interior, con un charco de luz en el piso. La que se acaba de apagar echa humo.
func _dibujar_velas() -> void:
	var encendidas := velas_encendidas()
	for i in _velas_en.size():
		var dentro := Vector2(_velas_en[i][1])
		var de_lado := Vector2(dentro.y, dentro.x)
		var borde := _centro(_velas_en[i][0]) + dentro * TAM * 0.5  # la cara del muro
		var vela := borde + dentro * TAM * 0.2
		var hierro := Color(0.18, 0.13, 0.1, 0.5 if espiritual else 1.0)
		draw_line(borde - de_lado * TAM * 0.2, borde + de_lado * TAM * 0.2, hierro, 4.0)  # la placa contra el muro
		draw_line(borde, vela, hierro, 3.0)  # el brazo
		if i < encendidas:
			var tiembla := 1.0 + 0.12 * sin(_t * 9.0 + i * 2.1) + 0.06 * sin(_t * 23.0 + i)
			if not espiritual:  # ilumina la sala; en el plano espiritual la luz no se ve, solo la llama
				draw_circle(vela + dentro * TAM * 0.3, TAM * 0.9, Color(COLOR_VELA, 0.1))
				draw_circle(vela + dentro * TAM * 0.15, TAM * 0.45, Color(COLOR_VELA, 0.16))
			draw_circle(vela, TAM * 0.15, Color(0.95, 0.88, 0.72))
			var punta := vela + dentro * TAM * 0.38 * tiembla
			draw_colored_polygon(PackedVector2Array([punta, vela + de_lado * TAM * 0.09, vela - dentro * TAM * 0.04, vela - de_lado * TAM * 0.09]), COLOR_VELA)
			draw_circle(vela + dentro * TAM * 0.05, TAM * 0.05, Color(1, 0.95, 0.8))
		else:
			draw_circle(vela, TAM * 0.15, Color(0.42, 0.36, 0.3, 0.5 if espiritual else 1.0))  # apagada: se ve oscura
			draw_circle(vela, TAM * 0.04, Color(0.12, 0.1, 0.08))
			if i == encendidas and _humo_t < DURACION_HUMO:
				var k := _humo_t / DURACION_HUMO
				for j in 4:  # el humo se aleja del muro ondulando y se desvanece
					var h := k * TAM * 0.5 + j * TAM * 0.07
					draw_circle(vela + dentro * h + de_lado * sin(h * 0.25) * TAM * 0.05, TAM * 0.03 * (1.0 + k), Color(0.8, 0.8, 0.85, 0.5 * (1.0 - k)))
