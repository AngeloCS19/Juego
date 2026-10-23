extends SceneTree
# Juega al jefe con la lógica real (por turnos, como las pruebas) y escribe la secuencia de teclas que lo vence.
# Uso: godot --headless --script res://tools/gen_jefe.gd -- res://salas/rio_jefe.json  → copiar SOLUCION= a "solucion".
# Si se cambia el jefe (mapa, ritmo, romper piedras), hay que regenerarla.
const DIRS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
var sala: SalaJefe
var barra: BarraHabilidades
var letras := ""
var fin := false

func _init() -> void:
	var ruta: String = OS.get_cmdline_user_args()[0]
	sala = Sala.desde_archivo(ruta)
	var lista: Array[Habilidad] = [Traspasar.new(), Reflejo.new()]
	barra = BarraHabilidades.new(lista)
	barra.configurar(["traspasar", "reflejo"])
	sala.completada.connect(func(): fin = true)
	sala.derrota.connect(func(): printerr("DERROTA en ", letras))
	var vueltas := 0
	while not fin and vueltas < 60:
		vueltas += 1
		_un_golpe()
	print("SOLUCION=", letras if fin else "NONE")
	quit()

func act(l: String) -> void:
	letras += l
	match l:
		"P":
			if barra.elegir(0, sala): barra.usar(sala)
		"F":
			if barra.elegir(1, sala): barra.usar(sala)
		"E":
			sala.empujar_enfrente()
		_:
			sala.mover(DIRS[l])

func libre(c: Vector2i, ignorar: Vector2i) -> bool:
	if sala.celda(c) != ".":
		return false
	var i := sala.piedra_en(c)
	return i < 0 or sala.piedras[i]["pos"] == ignorar

# BFS (jugador, piedra) hasta que la piedra quede en alguna meta. Devuelve letras.
func plan(piedra: Vector2i, metas: Array) -> String:
	var ini := Vector4i(sala.jugador.x, sala.jugador.y, piedra.x, piedra.y)
	var prev := {ini: null}
	var cola := [ini]
	while not cola.is_empty():
		var e4: Vector4i = cola.pop_front()
		var e := [Vector2i(e4.x, e4.y), Vector2i(e4.z, e4.w)]
		if e[1] in metas:
			var r := ""
			var k = e4
			while prev[k] != null:
				r = prev[k][1] + r
				k = prev[k][0]
			return r
		for l: String in DIRS:
			var d: Vector2i = DIRS[l]
			var j: Vector2i = e[0] + d
			var n
			var paso: String = l
			if j == e[1]:
				if not libre(e[1] + d, piedra) or e[1] + d == e[0]:
					continue
				n = [j, e[1] + d]
				paso = l + "E"
			elif libre(j, piedra):
				n = [j, e[1]]
			else:
				continue
			var n4 := Vector4i(n[0].x, n[0].y, n[1].x, n[1].y)
			if not prev.has(n4):
				prev[n4] = [e4, paso]
				cola.append(n4)
	return "X"

func _un_golpe() -> void:
	var t: Transformacion = sala.transformaciones[0]
	var metas := []
	for c in sala.datos["camino"]:
		var pre := t.aplicar(sala._vec(c))
		if sala.celda(pre) == ".":
			metas.append(pre)
	var mejor := "X"
	var elegida := Vector2i.ZERO
	for p in sala.piedras:
		var pl := plan(p["pos"], metas)
		if pl != "X" and (mejor == "X" or pl.length() < mejor.length()):
			mejor = pl
			elegida = p["pos"]
	if mejor == "X":
		act("D")  # esperar a que caigan más piedras
		return
	var fase := sala.fase
	for l in mejor:
		act(l)
		if fin or sala.fase != fase: return
	# donde quedó la piedra (si no hubo pushes, acercarse y mirarla)
	var destino := elegida
	var ult := mejor.rfind("E")
	if ult >= 0:
		destino = sala.jugador + sala.mirando
	else:
		var al_lado := plan_jugador(destino)
		for l in al_lado:
			act(l)
	if sala.piedra_en(destino) < 0:
		return
	var imagen := t.aplicar(destino)
	if not sala.piedras[sala.piedra_en(destino)]["marcada"]:
		act("F")
	var dir_piedra := ""
	for l: String in DIRS:
		if sala.jugador + DIRS[l] == destino: dir_piedra = l
	var esperas := 0
	while sala.narciso != imagen and esperas < 200:
		act(dir_piedra)
		esperas += 1
		if sala.piedra_en(destino) < 0 or sala.fase != fase: return
	act("P")
	if not fin and sala.fase == fase and sala.espiritual:
		act("P")

# Llevar al jugador junto a la piedra, mirándola.
func plan_jugador(piedra: Vector2i) -> String:
	var prev := {sala.jugador: null}
	var cola := [sala.jugador]
	while not cola.is_empty():
		var e: Vector2i = cola.pop_front()
		for l: String in DIRS:
			if e + DIRS[l] == piedra:
				var r: String = l
				var k = e
				while prev[k] != null:
					r = prev[k][1] + r
					k = prev[k][0]
				return r
		for l: String in DIRS:
			var j: Vector2i = e + DIRS[l]
			if libre(j, Vector2i(-99, -99)) and not prev.has(j):
				prev[j] = [e, l]
				cola.append(j)
	return ""
