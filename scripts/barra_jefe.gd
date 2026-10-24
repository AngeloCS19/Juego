class_name BarraJefe
extends Control
## Vida de Narciso (arriba al centro, como la BossBar de Minecraft) y corazones del jugador (arriba a la izquierda).
## La vida es su cabeza de frente con una flor por cada pétalo que le queda; al perder una, la flor cae.

const CABEZA := preload("res://assets/retratos/narciso_corona.svg")  # 600x330
const FLOR := preload("res://assets/sprites/flor_corona.svg")
const ANCHO := 260.0  # ancho en pantalla de la cabeza
const ESCALA := ANCHO / 600.0
const CAFE := Color("#2b1a14")
## La corona es un arco: elipse de centro (300,335) y radios 205 x 170 (ver docs/sprites.md).
const CENTRO_ARCO := Vector2(300, 335)
const RADIOS := Vector2(205, 170)
const ANGULOS := Vector2(162, 18)  # de la flor de la izquierda a la de la derecha, en grados

var _cabeza := TextureRect.new()
var _flores: Array[TextureRect] = []  # de izquierda a derecha
var _vivas: Array[bool] = []
var _corazones := 0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cabeza.texture = CABEZA
	_cabeza.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cabeza.size = Vector2(600, 330) * ESCALA
	_cabeza.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cabeza.self_modulate = Color(0.7, 0.9, 1.0, 0.5)  # self_: no tiñe a las flores, que son sus hijas. Fantasmal, como vista desde el plano celeste; solo las flores son sólidas
	add_child(_cabeza)
	hide()


func _process(_delta: float) -> void:
	_cabeza.position = Vector2((size.x - ANCHO) / 2, 8)


## Se llama al cargar la sala: solo se ve en la del jefe. Pone una flor por cada pétalo del combate.
func configurar(sala: Sala) -> void:
	for f in _flores:
		f.queue_free()
	_flores.clear()
	_vivas.clear()
	visible = sala is SalaJefe
	if not visible:
		return
	var total: int = (sala as SalaJefe).petalos()
	for i in total:
		var t := 0.5 if total == 1 else float(i) / (total - 1)
		var a := deg_to_rad(lerpf(ANGULOS.x, ANGULOS.y, t))
		var tam := lerpf(80, 100, sin(a))  # las del centro son más grandes
		var f := TextureRect.new()
		f.texture = FLOR
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.size = Vector2(tam, tam) * ESCALA
		f.pivot_offset = f.size / 2
		f.position = (CENTRO_ARCO + Vector2(cos(a), -sin(a)) * RADIOS) * ESCALA - f.size / 2
		_cabeza.add_child(f)
		_flores.append(f)
		_vivas.append(true)


## Cada cuadro: quita las flores que sobran (las de los extremos primero; la del centro es la última) y repinta los corazones.
func actualizar(sala: Sala) -> void:
	if not visible:
		return
	var jefe := sala as SalaJefe
	if jefe.corazones != _corazones:
		_corazones = jefe.corazones
		queue_redraw()
	var n := jefe.petalos()
	if n > _vivas.count(true):  # la fase volvió a empezar: recupera sus flores
		for i in _flores.size():
			_vivas[i] = true
			_flores[i].modulate.a = 1.0
			_flores[i].visible = true
	while _vivas.count(true) > n:
		var quitar := -1  # la viva más lejos del centro
		for i in _flores.size():
			if _vivas[i] and (quitar < 0 or absf(i - (_flores.size() - 1) / 2.0) > absf(quitar - (_flores.size() - 1) / 2.0)):
				quitar = i
		_vivas[quitar] = false
		_caer(_flores[quitar])


## La flor se cae y se desvanece.
func _caer(f: TextureRect) -> void:
	var t := create_tween().set_parallel()
	t.tween_property(f, "position:y", f.position.y + 60, 0.7).set_ease(Tween.EASE_IN)
	t.tween_property(f, "rotation", 1.2, 0.7)
	t.tween_property(f, "modulate:a", 0.0, 0.7)


func _draw() -> void:
	for i in _corazones:
		_corazon(Vector2(34 + i * 40, 34), 15.0)


## Corazón rojo con contorno café: dos círculos y un triángulo.
func _corazon(c: Vector2, r: float) -> void:
	var cuerpo := PackedVector2Array([c + Vector2(-r * 1.7, -r * 0.3), c + Vector2(r * 1.7, -r * 0.3), c + Vector2(0, r * 1.9)])
	for borde in [true, false]:
		var d := 3.0 if borde else 0.0
		var color: Color = CAFE if borde else Color("#d8342c")
		draw_circle(c + Vector2(-r * 0.8, -r * 0.4), r * 0.95 + d, color)
		draw_circle(c + Vector2(r * 0.8, -r * 0.4), r * 0.95 + d, color)
		var p := cuerpo.duplicate()
		if borde:
			for k in p.size():
				p[k] = c + (p[k] - c) * 1.12
		draw_colored_polygon(p, color)
