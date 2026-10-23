extends SceneTree
## Pruebas: godot --headless --script res://tests/test_reflexion.gd
## Revisa la matemática de la reflexión y que cada sala se pueda resolver con su "solucion".

var fallos := 0
var creados: Array[Node] = []  # nodos de prueba, se liberan al final


func _init() -> void:
	var h := Reflexion.new("horizontal", 4)
	_igual(h.aplicar(Vector2i(2, 6)), Vector2i(2, 2), "horizontal: misma distancia al eje")
	_igual(h.aplicar(Vector2i(3, 4)), Vector2i(3, 4), "horizontal: punto del eje invariante")
	_igual(Reflexion.new("vertical", 3).aplicar(Vector2i(1, 5)), Vector2i(5, 5), "vertical")
	var d := Reflexion.new("diagonal", 1)  # y = x + 1
	_igual(d.aplicar(Vector2i(2, 3)), Vector2i(2, 3), "diagonal: punto del eje invariante")
	_igual(d.aplicar(Vector2i(4, 1)), Vector2i(0, 5), "diagonal")
	var a := Reflexion.new("antidiagonal", 6)  # x + y = 6
	_igual(a.aplicar(Vector2i(1, 2)), Vector2i(4, 5), "antidiagonal")
	for eje in ["horizontal", "vertical", "diagonal", "antidiagonal"]:
		var r := Reflexion.new(eje, 2)
		var p := Vector2i(7, -3)
		_igual(r.aplicar(r.aplicar(p)), p, "%s: reflejar dos veces vuelve al inicio" % eje)

	for ruta in DirAccess.get_files_at("res://salas"):
		if ruta.ends_with(".json"):
			var r := _jugar(ruta, "")
			_igual(_jugar(ruta, r.sala.datos["solucion"]).completada, true, "%s se resuelve con su solución" % ruta)

	# Sin marcar la piedra con Reflejo no aparece su reflejo y no se cruza el vacío.
	_igual(_jugar("rio_01.json", "RRUPUUUU").completada, false, "sin Reflejo no se cruza el vacío")
	# Marcar dos veces la desmarca.
	_igual(_jugar("rio_01.json", "RRUFFPUUUU").completada, false, "Reflejo dos veces desmarca la piedra")
	# En la sala 1 Reflejo no está disponible.
	_igual(_jugar("rio_00.json", "F").sala.piedras.size(), 0, "la sala 1 no tiene piedras")

	# Chocar con una piedra solo gira al jugador; no la empuja ni avanza.
	var g := _jugar("rio_03.json", "LUR")
	_igual(g.sala.jugador, Vector2i(1, 5), "chocar con una piedra no avanza")
	_igual(g.sala.mirando, Vector2i.RIGHT, "chocar con una piedra gira al jugador hacia ella")
	_igual(g.sala.piedras[0]["pos"], Vector2i(2, 5), "chocar con una piedra no la empuja")
	_igual(_jugar("rio_03.json", "LURE").sala.piedras[0]["pos"], Vector2i(3, 5), "empujar mueve la piedra de enfrente")
	_igual(_jugar("rio_02.json", "RRE").sala.jugador, Vector2i(3, 6), "una piedra fija no se empuja")

	# Volver al plano normal sobre el vacío es caer y reiniciar la sala.
	var r := _jugar("rio_01.json", "RRUFPUUU")  # termina parado sobre el reflejo, encima del vacío
	var cayo := [false]
	r.sala.caida.connect(func(): cayo[0] = true)
	r.barra.usar(r.sala)
	_igual(cayo[0], true, "caer al volver al plano normal sobre el vacío")
	_igual(r.sala.jugador, Vector2i(1, 5), "la sala se reinicia después de caer")

	# Solo una habilidad activa; no se cambia mientras Traspasar está en curso.
	var sala_b := Sala.new()
	sala_b.cargar("res://salas/rio_00.json")
	var lista: Array[Habilidad] = [Traspasar.new(), Habilidad.new("Otra"), Habilidad.new("Bloqueada", false)]
	var barra := BarraHabilidades.new(lista)
	_igual(barra.elegir(2, sala_b), false, "no se elige una habilidad bloqueada")
	_igual(barra.elegir(1, sala_b), true, "se elige otra habilidad en el plano normal")
	_igual(barra.elegir(0, sala_b), true, "se vuelve a Traspasar")
	barra.usar(sala_b)
	_igual(sala_b.espiritual, true, "usar Traspasar cambia al plano espiritual")
	_igual(barra.elegir(1, sala_b), false, "no se cambia de habilidad en el plano espiritual")
	_igual(barra.activa, 0, "Traspasar sigue activa")
	barra.free()
	sala_b.free()

	for n in creados:
		n.free()
	print("Fallos: %d" % fallos)
	quit(1 if fallos else 0)


## Juega una sala con una secuencia de teclas: U D L R mueven (o giran, contra una piedra),
## E empuja la piedra de enfrente, P usa Traspasar, F usa Reflejo.
## Usa la barra de habilidades real, así que respeta qué habilidades tiene la sala.
func _jugar(ruta: String, secuencia: String) -> Dictionary:
	var sala := Sala.new()
	sala.cargar("res://salas/" + ruta)
	var lista: Array[Habilidad] = [Traspasar.new(), Reflejo.new()]
	var barra := BarraHabilidades.new(lista)
	barra.configurar(sala.datos.get("habilidades", ["traspasar", "reflejo"]))
	var resultado := {"sala": sala, "barra": barra, "completada": false}
	sala.completada.connect(func(): resultado["completada"] = true)
	var pasos := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for letra in secuencia:
		match letra:
			"P":
				if barra.elegir(0, sala):
					barra.usar(sala)
			"F":
				if barra.elegir(1, sala):
					barra.usar(sala)
			"E":
				sala.empujar_enfrente()
			_:
				sala.mover(pasos[letra])
	creados.append_array([sala, barra])
	return resultado


func _igual(obtenido, esperado, nombre: String) -> void:
	if obtenido != esperado:
		fallos += 1
		printerr("FALLA %s: se esperaba %s y salió %s" % [nombre, esperado, obtenido])
