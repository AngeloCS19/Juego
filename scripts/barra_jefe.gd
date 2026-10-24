class_name BarraJefe
extends Control
## Vida de Narciso (arriba al centro, como la BossBar de Minecraft) y corazones del jugador (arriba a la izquierda).
## La vida es su cabeza de frente con una flor por cada pétalo que le queda; al perder una, la flor cae.

const CABEZA := preload("res://assets/retratos/narciso_corona.svg")  # 600x330
const FLOR := preload("res://assets/sprites/flor_corona.svg")
const ANCHO := 260.0  # ancho en pantalla de la cabeza
const ESCALA := ANCHO / 600.0
const CAFE := Color("#2b1a14")
const APARECER := preload("res://shaders/aparecer.gdshader")
const DURACION_APARECER := 1.6
## La corona es un arco: elipse de centro (300,335) y radios 205 x 170 (ver docs/sprites.md).
const CENTRO_ARCO := Vector2(300, 335)
const RADIOS := Vector2(205, 170)
const ANGULOS := Vector2(162, 18)  # de la flor de la izquierda a la de la derecha, en grados

var _cabeza := TextureRect.new()
var _flores: Array[TextureRect] = []  # de izquierda a derecha
var _vivas: Array[bool] = []
var _corazones := 0
var _fundido := ShaderMaterial.new()  # la cabeza y sus flores lo comparten: aparecen juntas de abajo hacia arriba
var _avance := 0.0  # 0 = oculta, 1 = entera


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cabeza.texture = CABEZA
	_cabeza.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cabeza.size = Vector2(600, 330) * ESCALA
	_cabeza.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundido.shader = APARECER
	_cabeza.material = _fundido
	_cabeza.self_modulate = Color(0.7, 0.9, 1.0, 0.5)  # self_: no tiñe a las flores, que son sus hijas. Fantasmal, como vista desde el plano celeste; solo las flores son sólidas
	add_child(_cabeza)
	hide()


func _process(_delta: float) -> void:
	_cabeza.position = Vector2((size.x - ANCHO) / 2, 8)
	# La línea del fundido sube desde el pie de la cabeza hasta arriba (con margen para la franja suave).
	var alto := get_viewport_rect().size.y
	var arriba := _cabeza.global_position.y / alto - 0.06
	var abajo := (_cabeza.global_position.y + _cabeza.size.y) / alto + 0.06
	_fundido.set_shader_parameter("borde", lerpf(abajo, arriba, _avance))


## Al terminar el primer diálogo del jefe: la cabeza aparece poco a poco, de abajo hacia arriba.
func aparecer() -> void:
	if visible and _avance == 0.0:
		create_tween().tween_property(self, "_avance", 1.0, DURACION_APARECER).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Se llama al cargar la sala: solo se ve en la del jefe. Pone una flor por cada pétalo del combate.
func configurar(sala: Sala) -> void:
	for f in _flores:
		f.queue_free()
	_flores.clear()
	_vivas.clear()
	_avance = 0.0  # oculta hasta que Narciso termine de hablar
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
		f.material = _fundido
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
	while _vivas.count(true) < n:  # la fase volvió a empezar: vuelven sus flores, de la del centro hacia afuera
		var volver := -1
		for i in _flores.size():
			if not _vivas[i] and (volver < 0 or _al_centro(i) < _al_centro(volver)):
				volver = i
		_vivas[volver] = true
		var f := _flores[volver]
		f.get_meta("caida").kill()  # deshace la caída de _caer(), aunque no haya terminado
		f.position = f.get_meta("pos")
		f.rotation = 0.0
		f.modulate.a = 1.0
	while _vivas.count(true) > n:
		var quitar := -1  # la viva más lejos del centro
		for i in _flores.size():
			if _vivas[i] and (quitar < 0 or _al_centro(i) > _al_centro(quitar)):
				quitar = i
		_vivas[quitar] = false
		_caer(_flores[quitar])


## Qué tan lejos está la flor i de la del centro del arco.
func _al_centro(i: int) -> float:
	return absf(i - (_flores.size() - 1) / 2.0)


## La flor se cae y se desvanece.
func _caer(f: TextureRect) -> void:
	f.set_meta("pos", f.position)
	var t := create_tween().set_parallel()
	f.set_meta("caida", t)
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
