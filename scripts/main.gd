extends Node2D
## Punto de entrada: carga las salas en orden, lee los controles y gira la cámara.

const SALAS := [
	"res://salas/rio_00.json",
	"res://salas/rio_01.json",
	"res://salas/rio_02.json",
	"res://salas/rio_03.json",
	"res://salas/rio_04.json",
	"res://salas/rio_05.json",
	"res://salas/rio_06.json",
	"res://salas/rio_07.json",
	"res://salas/rio_08.json",
	"res://salas/rio_12.json",
	"res://salas/rio_09.json",
	"res://salas/rio_10.json",
	"res://salas/rio_11.json",
]
const FONDO_NORMAL := Color(0.1, 0.09, 0.08)
const FONDO_ESPIRITUAL := Color(0.03, 0.06, 0.12)
const UMBRAL_DESLIZAR := 30.0  # píxeles: un toque que se mueve menos que esto no es deslizar
const TIEMPO_EMPUJE := 0.3  # segundos que hay que sostener la dirección para empujar una piedra
const ID_HABILIDADES := 1000  # opción "Todas las habilidades" del menú debug; las salas usan su índice
const TECLAS_DIRECCION := {
	KEY_UP: Vector2i.UP, KEY_W: Vector2i.UP, KEY_DOWN: Vector2i.DOWN, KEY_S: Vector2i.DOWN,
	KEY_LEFT: Vector2i.LEFT, KEY_A: Vector2i.LEFT, KEY_RIGHT: Vector2i.RIGHT, KEY_D: Vector2i.RIGHT,
}

var indice := 0
var giro := 0  # cuartos de vuelta de la cámara (0 a 3)
var sala: Sala
var barra: BarraHabilidades
var _inicio_toque := Vector2.ZERO
var _dedo_abajo := false
var _dir_dedo := Vector2i.ZERO  # dirección (en pantalla) que el dedo sostiene, si deslizó o tocó una casilla vecina
var _empuje := 0.0  # cuánto tiempo lleva sostenida la dirección hacia una piedra
var _tween_giro: Tween
var _todas_habilidades := false  # modo debug: todas las habilidades en cualquier sala

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

	# Debug va debajo de la fila, no al lado: así la fila no se alarga y no tapa el texto de arriba.
	var esquina := VBoxContainer.new()
	esquina.add_theme_constant_override("separation", 8)
	esquina.add_child(acciones)
	if OS.is_debug_build():
		var debug := _crear_menu_debug()
		debug.size_flags_horizontal = Control.SIZE_SHRINK_END
		esquina.add_child(debug)

	_en_esquina(pantalla, barra, Control.PRESET_BOTTOM_LEFT)
	_en_esquina(pantalla, esquina, Control.PRESET_TOP_RIGHT)
	_en_esquina(pantalla, usar, Control.PRESET_BOTTOM_RIGHT)


## Menú solo para el desarrollador: saltar a cualquier sala y desbloquear todas las habilidades.
## OS.is_debug_build() es verdadero al jugar desde el editor (F5) y falso en una exportación
## final ("Export With Debug" desactivado), así que los jugadores nunca lo ven.
func _crear_menu_debug() -> MenuButton:
	var menu := MenuButton.new()
	menu.text = "Debug"
	menu.flat = false
	menu.custom_minimum_size = BarraHabilidades.TAM_BOTON
	menu.focus_mode = Control.FOCUS_NONE
	menu.add_theme_font_size_override("font_size", 22)
	BarraHabilidades._estilo(menu, Color(0.9, 0.3, 0.3), 2)
	var lista := menu.get_popup()
	lista.add_theme_font_size_override("font_size", 26)  # opciones grandes para el dedo
	lista.add_theme_constant_override("v_separation", 18)
	lista.add_check_item("Todas las habilidades", ID_HABILIDADES)
	lista.add_separator()
	for i in SALAS.size():
		var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SALAS[i]))
		lista.add_item("Sala %d · %s" % [i + 1, datos["nombre"]], i)
	lista.id_pressed.connect(_on_menu_debug.bind(lista))
	return menu


func _on_menu_debug(id: int, lista: PopupMenu) -> void:
	if id == ID_HABILIDADES:
		_todas_habilidades = not _todas_habilidades
		lista.set_item_checked(lista.get_item_index(id), _todas_habilidades)
	else:
		indice = id
		set_process_unhandled_input(true)  # por si ya se había terminado el templo
	_cargar_sala()


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
	var todas := ["traspasar", "reflejo"]
	barra.configurar(todas if _todas_habilidades else sala.datos.get("habilidades", todas))
	_on_plano_cambiado(false)


# shortcut: teclas fijas en código; pasarlas al Mapa de Entrada del proyecto cuando haya control de mando.
func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if evento.keycode in TECLAS_DIRECCION:
		_mover(TECLAS_DIRECCION[evento.keycode])
		return
	match evento.keycode:
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
## Mantener el dedo después de deslizar, o sobre una casilla vecina, cuenta como sostener esa dirección.
func _on_toque(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and _dedo_abajo and _dir_dedo == Vector2i.ZERO:
		var arrastre: Vector2 = evento.position - _inicio_toque
		if arrastre.length() >= UMBRAL_DESLIZAR:
			if absf(arrastre.x) > absf(arrastre.y):
				_dir_dedo = Vector2i(signi(int(arrastre.x)), 0)
			else:
				_dir_dedo = Vector2i(0, signi(int(arrastre.y)))
			_mover(_dir_dedo)  # un paso por deslizamiento, apenas se reconoce
		return
	if not (evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	_dedo_abajo = evento.pressed
	if evento.pressed:
		_inicio_toque = evento.position
		_dir_dedo = Vector2i.ZERO
		var diferencia := _casilla_tocada(evento.position) - sala.jugador
		if absi(diferencia.x) + absi(diferencia.y) == 1:
			sala.mover(diferencia)  # ya está en coordenadas del mundo, aunque la cámara esté girada
			_dir_dedo = _a_pantalla(diferencia)
		return
	if _dir_dedo == Vector2i.ZERO and _casilla_tocada(evento.position) == sala.jugador:
		barra.usar(sala)
	_dir_dedo = Vector2i.ZERO


func _casilla_tocada(posicion: Vector2) -> Vector2i:
	return Vector2i((sala.to_local(posicion) / Sala.TAM).floor())


## Empujar: sostener la dirección hacia una piedra que ya estás mirando.
func _process(delta: float) -> void:
	var dir := _a_mundo(_direccion_sostenida())
	if dir != Vector2i.ZERO and dir == sala.mirando and sala.hay_empujable_enfrente():
		_empuje += delta
		if _empuje >= TIEMPO_EMPUJE:
			_empuje = 0.0
			sala.empujar_enfrente()
	else:
		_empuje = 0.0


## Dirección en pantalla que el jugador mantiene presionada (teclado o dedo), o cero.
func _direccion_sostenida() -> Vector2i:
	if _dedo_abajo:
		return _dir_dedo
	for tecla in TECLAS_DIRECCION:
		if Input.is_key_pressed(tecla):
			return TECLAS_DIRECCION[tecla]
	return Vector2i.ZERO


## Las flechas siguen la pantalla: si la cámara está girada, la dirección se gira al revés.
func _mover(dir_pantalla: Vector2i) -> void:
	sala.mover(_a_mundo(dir_pantalla))


func _a_mundo(dir_pantalla: Vector2i) -> Vector2i:
	return Vector2i(Vector2(dir_pantalla).rotated(-giro * PI / 2).round())


func _a_pantalla(dir_mundo: Vector2i) -> Vector2i:
	return Vector2i(Vector2(dir_mundo).rotated(giro * PI / 2).round())


## La animación siempre termina en el ángulo de "giro", aunque se presione rápido varias veces:
## se detiene la animación anterior y se parte desde donde quedó.
func _girar(sentido: int) -> void:
	giro = posmod(giro + sentido, 4)
	if _tween_giro:
		_tween_giro.kill()
	var destino := pivote.rotation + wrapf(giro * PI / 2 - pivote.rotation, -PI, PI)  # por el camino más corto
	_tween_giro = create_tween()
	_tween_giro.tween_property(pivote, "rotation", destino, 0.25)


func _on_plano_cambiado(espiritual: bool) -> void:
	RenderingServer.set_default_clear_color(FONDO_ESPIRITUAL if espiritual else FONDO_NORMAL)
	etiqueta.text = "Sala %d · %s · Plano %s\nMover: flechas o deslizar · Habilidad: 1-9 · Usar: Espacio o botón Usar" % [
		indice + 1, sala.datos["nombre"], "espiritual" if espiritual else "normal"]
	if _todas_habilidades:
		etiqueta.text += "\nDEBUG: todas las habilidades"


func _on_caida() -> void:
	etiqueta.text += "\nCaíste: volviste al plano normal sobre el vacío o el agua."


func _on_sala_completada() -> void:
	indice += 1
	if indice < SALAS.size():
		_cargar_sala.call_deferred()  # diferido: la sala que avisa todavía está ejecutando su código
	else:
		set_process_unhandled_input(false)
		etiqueta.text = "Templo del Río completado. Pronto: el espíritu que gira."
