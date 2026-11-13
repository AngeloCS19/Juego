class_name Rotacion
extends Transformacion
## Rotación alrededor del centro de una casilla (el altar), en cuartos de vuelta.
##   "centro":  la casilla del altar
##   "cuartos": cuartos de vuelta en sentido horario (1 = 90°, 2 = 180°, 3 = 270°); negativo, antihorario
## En la cuadrícula solo caben cuartos de vuelta: con otro ángulo la imagen no caería en una casilla.

const TEX_RUEDA := preload("res://assets/sprites/rueda_piso.svg")
const CAL := Color("#fff6e0")
const TINTA := Color("#2b1a14")
const CELESTE := Color(0.55, 0.85, 1.0)
const CICLO_FLECHA := 2.2  # segundos que dura cada pasada de la flecha de apoyo

var centro: Vector2i
var cuartos: int
var radio := 0.0  # casillas que mide la rueda pintada en el piso, del centro al borde; 0 = sin rueda
var desde := 0  # hacia dónde apunta la punta de cal: 0 arriba, 1 derecha, 2 abajo, 3 izquierda


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


## La rueda pintada en el piso gira junto con las imágenes: el mismo ángulo, al mismo tiempo.
## Una de sus 16 puntas va pintada de cal: es "la que sale". Donde va a llegar solo está su silueta
## punteada, que no gira. Así la rueda dice cuánto y hacia dónde gira sin un solo número, y al
## Traspasar la punta entra en su silueta.
## draw_set_transform mueve y gira "la hoja" sobre la que se dibuja; al final se devuelve a su lugar.
func dibujar_piso(lienzo: CanvasItem, tam: float, k: float, espiritual: bool) -> bool:
	if radio <= 0.0:
		return false
	var r := radio * tam
	var c := (Vector2(centro) + Vector2(0.5, 0.5)) * tam
	var tinta := Color(CELESTE, 0.9) if espiritual else TINTA
	lienzo.draw_set_transform(c, k * cuartos * PI / 2)
	lienzo.draw_texture_rect(TEX_RUEDA, Rect2(-r, -r, r * 2, r * 2), false, Color(CELESTE, 0.22) if espiritual else Color(1, 1, 1, 0.4))
	var punta := _pico(r, _inicio())
	lienzo.draw_colored_polygon(punta, Color(CELESTE, 0.7) if espiritual else CAL)
	punta.append(punta[0])  # para cerrar el contorno
	lienzo.draw_polyline(punta, tinta, 3.0, true)
	lienzo.draw_set_transform(Vector2.ZERO)
	var silueta := _pico(r, _inicio() + cuartos * PI / 2)
	for i in 3:
		lienzo.draw_dashed_line(c + silueta[i], c + silueta[(i + 1) % 3], tinta, 2.5, 4.0)
	if guia >= 0.0 and not espiritual:
		_flecha(lienzo, c, r * 0.62)
	return true


## Hacia dónde apunta la punta de cal, en radianes: "desde" cuenta cuartos desde arriba, en sentido horario.
func _inicio() -> float:
	return (desde - 1) * PI / 2


## Los tres vértices de una punta de la rueda (las mismas medidas que en rueda_piso.svg).
func _pico(r: float, angulo: float) -> PackedVector2Array:
	var medio := PI / 16
	return PackedVector2Array([
		Vector2.from_angle(angulo - medio) * r * 0.4,
		Vector2.from_angle(angulo) * r * 0.85,
		Vector2.from_angle(angulo + medio) * r * 0.4,
	])


## La flecha de apoyo: sale de la punta de cal, llega a la silueta, se desvanece y vuelve a empezar.
## "guia" es un reloj en segundos; fmod lo convierte en un ciclo que se repite.
func _flecha(lienzo: CanvasItem, c: Vector2, r: float) -> void:
	var ciclo := fmod(guia, CICLO_FLECHA) / CICLO_FLECHA  # de 0 a 1, una y otra vez
	var avance := ease(clampf(ciclo / 0.55, 0.0, 1.0), -2.0)  # arranca y frena con suavidad
	var alfa := 1.0 - smoothstep(0.7, 0.95, ciclo)
	if avance < 0.03:
		return
	var fin := _inicio() + avance * cuartos * PI / 2
	lienzo.draw_arc(c, r, _inicio(), fin, 32, Color(TINTA, alfa), 9.0, true)
	lienzo.draw_arc(c, r, _inicio(), fin, 32, Color(CAL, alfa), 5.0, true)
	# La punta de la flecha apunta hacia donde sigue el giro.
	var punta := c + Vector2.from_angle(fin) * r
	var hacia := Vector2.from_angle(fin + signf(cuartos) * PI / 2)
	var lado := Vector2.from_angle(fin) * 11.0
	var triangulo := PackedVector2Array([punta + hacia * 15.0, punta + lado, punta - lado])
	lienzo.draw_colored_polygon(triangulo, Color(CAL, alfa))
	triangulo.append(triangulo[0])
	lienzo.draw_polyline(triangulo, Color(TINTA, alfa), 2.0, true)
