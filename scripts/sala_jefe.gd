class_name SalaJefe
extends Sala
## La sala de Narciso, el jefe del Templo del Río. Narciso flota en el plano espiritual, del otro
## lado del eje, y lanza piedras a la mitad del jugador. Se le golpea con el reflejo de esas piedras:
## si al traspasar el reflejo de una piedra marcada cae donde está él, se ve a sí mismo y pierde un pétalo.
##
## El JSON lleva "tipo": "jefe" y una lista de "fases". Cada fase trae su mapa, eje, inicio y piedras,
## y además:
##   "camino":       casillas por las que Narciso pasa, en orden y en ciclo
##   "cada":         cada cuántos turnos avanza una casilla
##   "lanzamientos": casillas donde caen sus piedras, en orden y en ciclo
##   "cada_lanzamiento": cada cuántos turnos lanza una
##   "golpes":       cuántos golpes aguanta esa fase
## "solucion" la juega en dificultad normal (un turno por acción).

signal golpeado

const TEX_NARCISO := preload("res://assets/sprites/narciso.svg")
const CORAZONES := 3
const AVISO := 2  # turnos que se ve la sombra antes de que caiga una piedra
const ATURDIDO := 3  # turnos que Narciso se queda quieto después de un golpe
const MAX_PIEDRAS := 4  # para que la arena no se llene
const MAX_MARCADAS := 2  # así no basta con marcar todas las piedras y traspasar al azar
const NARANJA := Color(1.0, 0.55, 0.2)

var todo: Dictionary  # el archivo completo; "datos" es la fase actual
var fase := 0
var narciso: Vector2i
var corazones := CORAZONES
var golpes := 0  # golpes que le faltan en esta fase
var sombras: Array[Dictionary] = []  # piedras en el aire: {"pos": Vector2i, "turnos": int}
var _paso := 0
var _turnos := 0
var _aturdido := 0
var _lanzadas := 0
var _marcadas: Array[Dictionary] = []  # piedras marcadas, de la más vieja a la más nueva


func cargar(ruta: String) -> void:
	todo = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	_usar_fase(0)


func _usar_fase(i: int) -> void:
	fase = i
	datos = todo.duplicate()
	datos.merge(todo["fases"][i], true)
	_preparar()


## Reiniciar repite solo la fase actual: las fases ganadas no se pierden.
func reiniciar() -> void:
	super()
	corazones = CORAZONES
	golpes = int(datos["golpes"])
	sombras.clear()
	_marcadas.clear()
	_paso = 0
	_turnos = 0
	_aturdido = 0
	_lanzadas = 0
	narciso = _vec(datos["camino"][0])


func _turno() -> void:
	_turnos += 1
	if _aturdido > 0:
		_aturdido -= 1
	elif _turnos % int(datos["cada"]) == 0:
		_paso = (_paso + 1) % datos["camino"].size()
		narciso = _vec(datos["camino"][_paso])
	for s in sombras.duplicate():
		s["turnos"] -= 1
		if s["turnos"] <= 0:
			sombras.erase(s)
			_caer(s["pos"])
			if corazones == 0:
				return  # _caer() ya reinició la fase
	if _turnos % int(datos["cada_lanzamiento"]) == 0 and piedras.size() + sombras.size() < MAX_PIEDRAS:
		var destino := _vec(datos["lanzamientos"][_lanzadas % datos["lanzamientos"].size()])
		_lanzadas += 1
		sombras.append({"pos": destino, "turnos": AVISO})
	queue_redraw()


## Cae una piedra lanzada. Si cae sobre el jugador, pierde un corazón y la piedra se rompe.
func _caer(c: Vector2i) -> void:
	if c == jugador:
		corazones -= 1
		if corazones == 0:
			reiniciar()
			derrota.emit()
		return
	if piedra_en(c) < 0 and celda(c) == ".":
		piedras.append({"pos": c, "fija": false, "flota": false, "marcada": false})


## El golpe ocurre al pasar al plano espiritual: Traspasar es el gatillo.
func cambiar_plano() -> void:
	var antes := espiritual
	var donde := narciso  # dónde estaba al traspasar, antes de que avance su turno
	super()
	if espiritual and not antes:
		_revisar_golpe(donde)


func _revisar_golpe(donde: Vector2i) -> void:
	var acierto := false
	for p in piedras.duplicate():
		if p["marcada"] and _llega(p["pos"], donde):
			piedras.erase(p)  # la piedra que lo alcanzó se deshace
			_marcadas.erase(p)
			acierto = true
	if not acierto:
		return
	golpes -= 1
	_aturdido = ATURDIDO
	golpeado.emit()
	if golpes > 0:
		queue_redraw()
	elif fase + 1 < todo["fases"].size():
		_usar_fase(fase + 1)
	else:
		completada.emit()


func _llega(c: Vector2i, donde: Vector2i) -> bool:
	for t in transformaciones:
		if t.aplicar(c) == donde:
			return true
	return false


## Solo dos piedras marcadas a la vez: marcar una tercera desmarca la más vieja.
func marcar_enfrente() -> bool:
	var i := piedra_en(jugador + mirando)
	if i < 0:
		return false
	var p := piedras[i]
	if not p["marcada"] and _marcadas.size() == MAX_MARCADAS:
		var vieja: Dictionary = _marcadas.pop_front()
		vieja["marcada"] = false
	if p["marcada"]:
		_marcadas.erase(p)
	else:
		_marcadas.append(p)
	return super()


## Pétalos que le quedan a la corona en todo el combate.
func petalos() -> int:
	var total := golpes
	for i in range(fase + 1, todo["fases"].size()):
		total += int(todo["fases"][i]["golpes"])
	return total


func estado() -> String:
	return "Corazones: %s · Pétalos de Narciso: %d" % ["♥".repeat(corazones), petalos()]


func _draw() -> void:
	super()
	for s in sombras:
		# La sombra crece mientras la piedra se acerca.
		var radio: float = TAM * (0.45 - 0.1 * (s["turnos"] - 1))
		draw_circle(_centro(s["pos"]), radio, Color(0, 0, 0, 0.45))
	# Narciso solo existe en el plano espiritual; en el normal se adivina su silueta.
	var enojo := float(fase) / maxf(1.0, todo["fases"].size() - 1)
	var color := CELESTE.lerp(NARANJA, enojo)
	color.a = 1.0 if espiritual else 0.35
	var r := _rect(narciso).grow(4)
	draw_texture_rect(_silueta(TEX_NARCISO), r, false, color)
	# Su corona de narcisos: un pétalo por cada golpe que le falta.
	var n := petalos()
	for k in n:
		var angulo := TAU * k / n - PI / 2
		draw_circle(_centro(narciso) + Vector2.from_angle(angulo) * TAM * 0.42, 5.0, Color(1, 1, 0.92, color.a))
