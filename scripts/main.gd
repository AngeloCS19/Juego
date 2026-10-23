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

var indice := 0
var giro := 0  # cuartos de vuelta de la cámara (0 a 3)
var sala: Sala
var barra: BarraHabilidades

@onready var pivote: Node2D = $Pivote
@onready var etiqueta: Label = $Interfaz/Etiqueta


func _ready() -> void:
	pivote.position = get_viewport_rect().size / 2
	var lista: Array[Habilidad] = [Traspasar.new(), Reflejo.new()]
	barra = BarraHabilidades.new(lista)
	barra.position = Vector2(16, get_viewport_rect().size.y - 56)
	$Interfaz.add_child(barra)
	_cargar_sala()


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
			var i: int = evento.keycode - KEY_1
			if not barra.elegir(i, sala) and i < barra.habilidades.size() and barra.habilidades[i].disponible:
				_on_plano_cambiado(sala.espiritual)
				etiqueta.text += "\nTermina la habilidad activa antes de elegir otra."
		KEY_R:
			sala.reiniciar()
		KEY_Q:
			_girar(-1)
		KEY_E:
			_girar(1)


## Las flechas siguen la pantalla: si la cámara está girada, la dirección se gira al revés.
func _mover(dir_pantalla: Vector2i) -> void:
	var dir := Vector2(dir_pantalla).rotated(-giro * PI / 2).round()
	sala.mover(Vector2i(dir))


func _girar(sentido: int) -> void:
	giro = posmod(giro + sentido, 4)
	create_tween().tween_property(pivote, "rotation", pivote.rotation + sentido * PI / 2, 0.25)


func _on_plano_cambiado(espiritual: bool) -> void:
	RenderingServer.set_default_clear_color(FONDO_ESPIRITUAL if espiritual else FONDO_NORMAL)
	etiqueta.text = "Sala %d · %s · Plano %s\nFlechas o WASD: mover · 1-9: elegir habilidad · Espacio: usarla · R: reiniciar · Q/E: girar cámara" % [
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
