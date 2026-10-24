class_name Sonido
## Efectos de sonido. Desde cualquier script: Sonido.tocar("empujar").
## Cada efecto es un .ogg de assets/sonidos/ (salen de tools/musica/efectos.js). Por cada sonido se crea
## un AudioStreamPlayer que se borra solo al terminar, así pueden sonar varios a la vez.
## También guarda el volumen de los buses de audio "Musica" y "Efectos", que el menú cambia.

const VOLUMENES := [0.0, -10.0, -80.0]  # dB: Alta, Media, Apagada
const NOMBRES := ["Alta", "Media", "Apagada"]

static var _cache := {}  # nombre -> AudioStream, para cargar cada archivo una sola vez
static var _nivel := {}  # bus -> índice en VOLUMENES


static func tocar(nombre: String, volumen_db := 0.0, tono := 1.0) -> void:
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return  # las pruebas juegan antes de que exista el árbol: ahí no suena nada
	if not _cache.has(nombre):
		_cache[nombre] = load("res://assets/sonidos/%s.ogg" % nombre)
	var p := AudioStreamPlayer.new()
	p.stream = _cache[nombre]
	p.volume_db = volumen_db
	p.pitch_scale = tono
	p.bus = bus("Efectos")
	p.autoplay = true  # empieza al entrar al árbol
	p.process_mode = Node.PROCESS_MODE_ALWAYS  # los botones del menú suenan con el juego en pausa
	p.finished.connect(p.queue_free)
	arbol.root.add_child.call_deferred(p)  # diferido: puede llamarse mientras el árbol está ocupado


## Devuelve el nombre del bus y lo crea si todavía no existe.
static func bus(nombre: String) -> String:
	if AudioServer.get_bus_index(nombre) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, nombre)
	return nombre


## Pasa el bus al siguiente volumen (Alta, Media, Apagada).
static func cambiar_volumen(nombre: String) -> void:
	_nivel[nombre] = (_nivel.get(nombre, 0) + 1) % VOLUMENES.size()
	var i := AudioServer.get_bus_index(bus(nombre))
	AudioServer.set_bus_volume_db(i, VOLUMENES[_nivel[nombre]])
	AudioServer.set_bus_mute(i, _nivel[nombre] == VOLUMENES.size() - 1)


## Texto del botón del menú, por ejemplo "Efectos: Media".
static func texto_volumen(nombre: String, etiqueta: String) -> String:
	return "%s: %s" % [etiqueta, NOMBRES[_nivel.get(nombre, 0)]]
