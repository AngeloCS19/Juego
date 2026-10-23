class_name SalaHuida
extends Sala
## Un tramo de la huida. Después de perder su corona, Narciso enfurece y el templo se derrumba:
## él persigue al jugador y cada casilla de piso que deja atrás se vuelve lava.
## Cada tramo es una sala corta con una mecánica que el jugador ya conoce (nada nuevo bajo presión),
## y es un punto de control: si Narciso lo alcanza, solo se repite ese tramo.
##
## El JSON lleva "tipo": "huida" y además:
##   "camino": casillas por las que Narciso pasa, en orden (de la entrada a la salida)
##   "espera": turnos antes de que empiece a perseguir
##   "cada":   cada cuántos turnos avanza una casilla
## Igual que el jefe: en normal avanza cuando el jugador actúa, en difícil con un reloj.

var narciso: Vector2i
var _paso := 0
var _turnos := 0


func reiniciar() -> void:
	mapa = datos["mapa"].duplicate()  # la lava que dejó Narciso no debe quedar en los datos de la sala
	super()
	_paso = 0
	_turnos = 0
	narciso = _vec(datos["camino"][0])


func _turno() -> void:
	_turnos += 1
	var camino: Array = datos["camino"]
	var avanza := _turnos > int(datos["espera"]) and (_turnos - int(datos["espera"])) % int(datos["cada"]) == 0
	if avanza and _paso + 1 < camino.size():
		var atras := narciso
		_paso += 1
		narciso = _vec(camino[_paso])
		if celda(atras) == "." and piedra_en(atras) < 0:
			mapa[atras.y] = mapa[atras.y].substr(0, atras.x) + "^" + mapa[atras.y].substr(atras.x + 1)
	if narciso == jugador:
		reiniciar()
		derrota.emit()
	queue_redraw()


func _draw() -> void:
	super()
	# Rojo lava, más oscuro que el naranja del jugador para no confundirlos.
	# Furioso, ya casi se ve en el plano normal.
	var color := Color(0.85, 0.15, 0.1, 1.0 if espiritual else 0.8)
	draw_texture_rect(_silueta(SalaJefe.TEX_NARCISO), _rect(narciso).grow(4), false, color)
