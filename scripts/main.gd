extends Node2D
## Punto de entrada: carga las salas en orden, lee los controles y gira la cámara.

const SALAS := [
	"res://salas/rio_00.json",
	"res://salas/rio_01.json",
	"res://salas/rio_02.json",
	"res://salas/rio_03.json",
	"res://salas/rio_04.json",
]
const FONDO_NORMAL := Color(0.1, 0.09, 0.08)
const FONDO_ESPIRITUAL := Color(0.03, 0.06, 0.12)
const UMBRAL_DESLIZAR := 30.0  # píxeles: un toque que se mueve menos que esto no es deslizar

var indice := 0
var giro := 0  # cuartos de vuelta de la cámara (0 a 3)
var sala: Sala
var barra: BarraHabilidades
var _inicio_toque := Vector2.ZERO

@onready var pivote: Node2D = $Pivote
@onready var etiqueta: Label = $Interfaz/Etiqueta


func _ready() -> void:
	var lista: Array[Habilidad] = [Traspasar.new(), Reflejo.new()]
	barra = BarraHabilidades.new(lista)
	barra.pedida.connect(_elegir)
	_crear_controles_tactiles()
	get_viewport().size_changed.connect(_centrar)
	_centrar()
	_cargar_sala()


## Controles en pantalla para jugar con el dedo (o con el mouse en la PC).
## "pantalla" cubre toda la ventana: recibe los toques sobre el mapa,
## y los botones, que son sus hijos, quedan por encima y reciben los suyos primero.
func _crear_controles_tactiles() -> void:
	var pantalla := Control.new()
	pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.gui_input.connect(_on_toque)
	$Interfaz.add_child(pantalla)
	$Interfaz/Etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	acciones.add_child(BarraHabilidades.crear_boton("Girar ⟲", _girar.bind(-1)))
	acciones.add_child(BarraHabilidades.crear_boton("Girar ⟳", _girar.bind(1)))
	acciones.add_child(BarraHabilidades.crear_boton("Reiniciar", func(): sala.reiniciar()))
	var usar := BarraHabilidades.crear_boton("Usar", func(): barra.usar(sala), BarraHabilidades.COLOR_ACTIVA)
	usar.custom_minimum_size = Vector2(120, 96)

	_en_esquina(pantalla, barra, Control.PRESET_BOTTOM_LEFT)
	_en_esquina(pantalla, acciones, Control.PRESET_TOP_RIGHT)
	_en_esquina(pantalla, usar, Control.PRESET_BOTTOM_RIGHT)


func _en_esquina(padre: Control, nodo: Control, esquina: Control.LayoutPreset) -> void:
	padre.add_child(nodo)
	nodo.set_anchors_and_offsets_preset(esquina, Control.PRESET_MODE_MINSIZE, 16)
	# Que crezca hacia adentro de la pantalla si su contenido cambia de tamaño.
	nodo.grow_horizontal = Control.GROW_DIRECTION_BEGIN if esquina in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_END
	nodo.grow_vertical = Control.GROW_DIRECTION_BEGIN if esquina in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_END


## La pantalla del celular puede tener otra proporción: la sala siempre queda al centro.
func _centrar() -> void:
	pivote.position = get_viewport_rect().size / 2


func _cargar_sala() -> void:
	if sala:
		sala.queue_free()
	sala = Sala.new()
	sala.cargar(SALAS[indice])
	sala.position = -Vector2(sala.tamano) * Sala.TAM / 2  # centra la sala en el pivote
	sala.completada.connect(_on_sala_completada)
	sala.plano_cambiado.connect(_on_plano_cambiado)
	sala.caida.connect(_on_caida)
	pivote.add_child(sala)
	barra.configurar(sala.datos.get("habilidades", ["traspasar", "reflejo"]))
	_on_plano_cambiado(false)


# shortcut: teclas fijas en código; pasarlas al Mapa de Entrada del proyecto cuando haya control de mando.
func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	match evento.keycode:
		KEY_UP, KEY_W:
			_mover(Vector2i.UP)
		KEY_DOWN, KEY_S:
			_mover(Vector2i.DOWN)
		KEY_LEFT, KEY_A:
			_mover(Vector2i.LEFT)
		KEY_RIGHT, KEY_D:
			_mover(Vector2i.RIGHT)
		KEY_SPACE:
			barra.usar(sala)
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			_elegir(evento.keycode - KEY_1)
		KEY_R:
			sala.reiniciar()
		KEY_Q:
			_girar(-1)
		KEY_E:
			_girar(1)


func _elegir(i: int) -> void:
	if not barra.elegir(i, sala) and i < barra.habilidades.size() and barra.habilidades[i].disponible:
		_on_plano_cambiado(sala.espiritual)
		etiqueta.text += "\nTermina la habilidad activa antes de elegir otra."


## Deslizar mueve una casilla en esa dirección. Tocar una casilla vecina mueve hacia ella,
## y tocar al personaje usa la habilidad activa.
func _on_toque(evento: InputEvent) -> void:
	if not (evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	if evento.pressed:
		_inicio_toque = evento.position
		return
	var arrastre: Vector2 = evento.position - _inicio_toque
	if arrastre.length() >= UMBRAL_DESLIZAR:
		if absf(arrastre.x) > absf(arrastre.y):
			_mover(Vector2i(signi(int(arrastre.x)), 0))
		else:
			_mover(Vector2i(0, signi(int(arrastre.y))))
		return
	var tocada := Vector2i((sala.to_local(evento.position) / Sala.TAM).floor())
	var diferencia := tocada - sala.jugador
	if diferencia == Vector2i.ZERO:
		barra.usar(sala)
	elif absi(diferencia.x) + absi(diferencia.y) == 1:
		sala.mover(diferencia)  # ya está en coordenadas del mundo, aunque la cámara esté girada


## Las flechas siguen la pantalla: si la cámara está girada, la dirección se gira al revés.
func _mover(dir_pantalla: Vector2i) -> void:
	var dir := Vector2(dir_pantalla).rotated(-giro * PI / 2).round()
	sala.mover(Vector2i(dir))


func _girar(sentido: int) -> void:
	giro = posmod(giro + sentido, 4)
	create_tween().tween_property(pivote, "rotation", pivote.rotation + sentido * PI / 2, 0.25)


func _on_plano_cambiado(espiritual: bool) -> void:
	RenderingServer.set_default_clear_color(FONDO_ESPIRITUAL if espiritual else FONDO_NORMAL)
	etiqueta.text = "Sala %d · %s · Plano %s\nMover: flechas, WASD o deslizar · Habilidad: 1-9 o tocarla · Usar: Espacio, botón Usar o tocar al personaje" % [
		indice + 1, sala.datos["nombre"], "espiritual" if espiritual else "normal"]


func _on_caida() -> void:
	etiqueta.text += "\nCaíste: volviste al plano normal sobre el vacío o el agua."


func _on_sala_completada() -> void:
	indice += 1
	if indice < SALAS.size():
		_cargar_sala.call_deferred()  # diferido: la sala que avisa todavía está ejecutando su código
	else:
		set_process_unhandled_input(false)
		etiqueta.text = "Templo del Río completado. Pronto: el espíritu que gira."
