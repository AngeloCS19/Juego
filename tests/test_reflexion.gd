extends SceneTree
## Pruebas: godot --headless --script res://tests/test_reflexion.gd
## Revisa la matemática de la reflexión y que cada sala se pueda resolver con su "solucion".

var fallos := 0


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

	var pasos := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for ruta in DirAccess.get_files_at("res://salas"):
		var sala := Sala.new()
		sala.cargar("res://salas/" + ruta)
		var lista := [false]
		sala.completada.connect(func(): lista[0] = true)
		for letra in sala.datos["solucion"]:
			if letra == "P":
				sala.cambiar_plano()
			else:
				sala.mover(pasos[letra])
		_igual(lista[0], true, "%s se resuelve con su solución" % ruta)
		sala.free()

	# Volver al plano normal sobre el vacío es caer y reiniciar la sala.
	var sala := Sala.new()
	sala.cargar("res://salas/rio_00.json")
	var cayo := [false]
	sala.caida.connect(func(): cayo[0] = true)
	for letra in "PRRUUU":  # termina parado sobre el reflejo, encima del vacío
		if letra == "P":
			sala.cambiar_plano()
		else:
			sala.mover(pasos[letra])
	sala.cambiar_plano()
	_igual(cayo[0], true, "caer al volver al plano normal sobre el vacío")
	_igual(sala.jugador, Vector2i(1, 5), "la sala se reinicia después de caer")
	sala.free()

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

	print("Fallos: %d" % fallos)
	quit(1 if fallos else 0)


func _igual(obtenido, esperado, nombre: String) -> void:
	if obtenido != esperado:
		fallos += 1
		printerr("FALLA %s: se esperaba %s y salió %s" % [nombre, esperado, obtenido])
