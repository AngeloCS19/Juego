class_name Musica
extends Node
## Música del juego. Cada pieza viene en capas (el templo: marimba, bajo y ocarina; el jefe, una por fase).
## Cada capa está grabada dos veces con el mismo largo: la del plano normal y la del espiritual
## (filtrada, con más eco y un brillo cristalino). Todas suenan siempre a la vez, en sincronía,
## y solo cambia cuáles se oyen: así, al Traspasar la música se cruza sin cortarse.
## Los archivos salen de tools/musica/ (ver el README).

const PIEZAS := {
	"templo": ["templo_marimba", "templo_bajo", "templo_ocarina"],
	"huida": ["huida"],  # las cuatro melodías de Angelo en flauta, tocadas por la ocarina
	# Narciso: una capa más por fase. El bombo cae en cada paso suyo, así que cada dificultad
	# tiene su propia grabación, a su velocidad (RITMO_NORMAL y RITMO_DIFICIL de main.gd).
	"jefe_normal": ["jefe_normal_base", "jefe_normal_ocarina", "jefe_normal_fase3"],
	"jefe_dificil": ["jefe_dificil_base", "jefe_dificil_ocarina", "jefe_dificil_fase3"],
	"altar": ["altar"],  # el arpegio de la ocarina del jefe, lento y en calma
}
## Índice de SALAS (main.gd) desde el que suena cada capa: la pieza se arma a lo largo del templo.
const DESDE := [0, 6, 12]
const SALIDA := 1.5  # segundos que tarda en apagarse una pieza al cambiar a otra
const CRUCE := 0.6  # segundos que tarda la música en pasar de un plano al otro
const ENTRADA := 3.0  # segundos que tarda una capa nueva en entrar
const SILENCIO := -60.0  # dB: tan bajo que no se oye

var _normal: Array[AudioStreamPlayer] = []
var _espiritual: Array[AudioStreamPlayer] = []
var _pieza := ""  # la que suena ("" = silencio)
var _capas := 0  # cuántas capas se oyen
var _en_espiritual := false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue sonando con el menú abierto
	# Un bus de audio propio para la música: el menú cambia su volumen sin tocar los efectos.
	Sonido.bus("Musica")


func _crear(ruta: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load(ruta)
	stream.loop = true  # los archivos están hechos para empalmar el final con el inicio
	p.stream = stream
	p.bus = "Musica"
	p.volume_db = SILENCIO
	add_child(p)
	return p


## Cuántas capas suenan en la sala "indice" (0 en las salas sin esta música).
static func capas_en(indice: int) -> int:
	return DESDE.filter(func(desde): return indice >= desde).size()


## Toca una pieza de PIEZAS ("" = silencio) con sus primeras "capas" capas.
## Si ya sonaba esa pieza, sigue sin volver a empezar (así la huida no se corta entre tramos).
func tocar(pieza: String, capas := 99) -> void:
	if pieza != _pieza:
		_pieza = pieza
		_apagar(_normal + _espiritual)
		_normal.clear()
		_espiritual.clear()
		for capa in PIEZAS.get(pieza, []):
			_normal.append(_crear("res://assets/musica/%s_normal.ogg" % capa))
			_espiritual.append(_crear("res://assets/musica/%s_espiritual.ogg" % capa))
		for p in _normal + _espiritual:
			p.play()  # todas juntas, en el mismo cuadro, para que queden en sincronía
	_capas = capas
	_mezclar(ENTRADA)


## La pieza anterior se apaga despacio y después se borra.
func _apagar(viejos: Array[AudioStreamPlayer]) -> void:
	for p in viejos:
		var t := create_tween()
		t.tween_property(p, "volume_db", SILENCIO, SALIDA)
		t.tween_callback(p.queue_free)


## El jugador cambió de plano: se cruza a la versión del otro plano.
func plano(espiritual: bool) -> void:
	if espiritual != _en_espiritual:
		_en_espiritual = espiritual
		_mezclar(CRUCE)


## Lleva cada reproductor a su volumen: se oyen las capas activas, solo en el plano actual.
func _mezclar(duracion: float) -> void:
	if _tween:
		_tween.kill()
	if _normal.is_empty():
		return  # silencio: no hay nada que mezclar
	_tween = create_tween().set_parallel()
	for i in _normal.size():
		var activa := i < _capas
		_fundir(_normal[i], activa and not _en_espiritual, duracion)
		_fundir(_espiritual[i], activa and _en_espiritual, duracion)


## Sube o baja un reproductor. Se interpola el volumen lineal (no los dB): así, a mitad del
## cruce, las dos versiones suman lo mismo que una sola y la música no baja de golpe.
func _fundir(p: AudioStreamPlayer, oir: bool, duracion: float) -> void:
	var hacia := 1.0 if oir else 0.0
	_tween.tween_method(func(v: float): p.volume_db = linear_to_db(maxf(v, 0.001)), db_to_linear(p.volume_db), hacia, duracion)

