class_name Musica
extends Node
## Música del Templo del Río (ocarina y marimba). La pieza viene en capas: marimba, bajo y ocarina.
## Cada capa está grabada dos veces con el mismo largo: la del plano normal y la del espiritual
## (filtrada, con más eco y un brillo cristalino). Las seis suenan siempre a la vez, en sincronía,
## y solo cambia cuáles se oyen: así, al Traspasar la música se cruza sin cortarse.
## Los archivos salen de tools/musica/ (ver el README).

const CAPAS := ["marimba", "bajo", "ocarina"]
## Índice de SALAS (main.gd) desde el que suena cada capa: la pieza se arma a lo largo del templo.
const DESDE := [0, 6, 12]
const CRUCE := 0.6  # segundos que tarda la música en pasar de un plano al otro
const ENTRADA := 3.0  # segundos que tarda una capa nueva en entrar
const SILENCIO := -60.0  # dB: tan bajo que no se oye
const VOLUMENES := [0.0, -10.0, SILENCIO]  # Alta, Media, Apagada (dB del bus "Musica")
const NOMBRES_VOLUMEN := ["Alta", "Media", "Apagada"]

var volumen := 0  # índice en VOLUMENES
var _normal: Array[AudioStreamPlayer] = []
var _espiritual: Array[AudioStreamPlayer] = []
var _capas := 0  # cuántas capas se oyen
var _en_espiritual := false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue sonando con el menú abierto
	# Un bus de audio propio para la música: el menú cambia su volumen sin tocar los efectos.
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, "Musica")
	for capa in CAPAS:
		_normal.append(_crear("res://assets/musica/templo_%s_normal.ogg" % capa))
		_espiritual.append(_crear("res://assets/musica/templo_%s_espiritual.ogg" % capa))


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


## Elige cuántas capas se oyen. Con 0 la música se apaga.
func tocar(capas: int) -> void:
	if capas > 0 and not _normal[0].playing:
		for p in _normal + _espiritual:
			p.play()  # todas juntas, en el mismo cuadro, para que queden en sincronía
	_capas = capas
	_mezclar(ENTRADA)


## El jugador cambió de plano: se cruza a la versión del otro plano.
func plano(espiritual: bool) -> void:
	if espiritual != _en_espiritual:
		_en_espiritual = espiritual
		_mezclar(CRUCE)


## Lleva cada reproductor a su volumen: se oyen las capas activas, solo en el plano actual.
func _mezclar(duracion: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	for i in CAPAS.size():
		var activa := i < _capas
		_fundir(_normal[i], activa and not _en_espiritual, duracion)
		_fundir(_espiritual[i], activa and _en_espiritual, duracion)


## Sube o baja un reproductor. Se interpola el volumen lineal (no los dB): así, a mitad del
## cruce, las dos versiones suman lo mismo que una sola y la música no baja de golpe.
func _fundir(p: AudioStreamPlayer, oir: bool, duracion: float) -> void:
	var hacia := 1.0 if oir else 0.0
	_tween.tween_method(func(v: float): p.volume_db = linear_to_db(maxf(v, 0.001)), db_to_linear(p.volume_db), hacia, duracion)


## Pasa al siguiente volumen (Alta, Media, Apagada) y devuelve su nombre para el menú.
func cambiar_volumen() -> String:
	volumen = (volumen + 1) % VOLUMENES.size()
	var bus := AudioServer.get_bus_index("Musica")
	AudioServer.set_bus_volume_db(bus, VOLUMENES[volumen])
	AudioServer.set_bus_mute(bus, VOLUMENES[volumen] == SILENCIO)
	return texto_volumen()


func texto_volumen() -> String:
	return "Música: " + NOMBRES_VOLUMEN[volumen]
