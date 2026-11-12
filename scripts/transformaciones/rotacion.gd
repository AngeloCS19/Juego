class_name Rotacion
extends Transformacion
## Rotación alrededor del centro de una casilla (el altar), en cuartos de vuelta.
##   "centro":  la casilla del altar
##   "cuartos": cuartos de vuelta en sentido horario (1 = 90°, 2 = 180°, 3 = 270°); negativo, antihorario
## En la cuadrícula solo caben cuartos de vuelta: con otro ángulo la imagen no caería en una casilla.

var centro: Vector2i
var cuartos: int


func _init(p_centro: Vector2i, p_cuartos: int) -> void:
	marca = "giro"
	centro = p_centro
	cuartos = p_cuartos


## Un cuarto de vuelta horario lleva (dx, dy) a (-dy, dx): "y" crece hacia abajo en la pantalla.
## La distancia al centro no cambia, y el centro es el único punto que no se mueve.
func aplicar(c: Vector2i) -> Vector2i:
	var d := c - centro
	for i in posmod(cuartos, 4):
		d = Vector2i(-d.y, d.x)
	return centro + d


## La imagen no viaja en línea recta: gira alrededor del altar, siempre a la misma distancia.
func viaje(origen: Vector2, _destino: Vector2, k: float) -> Vector2:
	var c := (Vector2(centro) + Vector2(0.5, 0.5)) * Sala.TAM
	return c + (origen - c).rotated(k * cuartos * PI / 2)


## En el plano espiritual: el ángulo en grande, alrededor del altar.
func dibujar(lienzo: CanvasItem, tam: float, _tamano_sala: Vector2i, color: Color) -> void:
	_angulo(lienzo, tam, tam * 1.3, color, 3.0)


## En el plano normal: el mismo ángulo, pequeño, tallado sobre el altar.
func dibujar_normal(lienzo: CanvasItem, tam: float) -> void:
	_angulo(lienzo, tam, tam * 0.36, Color("#2b1a14"), 2.5)


## Un ángulo como se dibuja en geometría: dos rayos que salen del centro y un arco con flecha
## que va del primero al segundo en el sentido del giro.
func _angulo(lienzo: CanvasItem, tam: float, radio: float, color: Color, ancho: float) -> void:
	var c := (Vector2(centro) + Vector2(0.5, 0.5)) * tam
	var inicio := -PI / 2  # el primer rayo apunta hacia arriba
	var fin := inicio + cuartos * PI / 2
	lienzo.draw_line(c, c + Vector2.from_angle(inicio) * radio, color, ancho)
	lienzo.draw_line(c, c + Vector2.from_angle(fin) * radio, color, ancho)
	lienzo.draw_arc(c, radio * 0.7, inicio, fin, 24, color, ancho)
	# La punta de la flecha, al final del arco, apunta hacia donde sigue el giro.
	var punta := c + Vector2.from_angle(fin) * radio * 0.7
	var hacia := Vector2.from_angle(fin + signf(cuartos) * PI / 2)
	var lado := Vector2.from_angle(fin) * radio * 0.16
	lienzo.draw_colored_polygon(PackedVector2Array([punta + hacia * radio * 0.28, punta + lado, punta - lado]), color)
