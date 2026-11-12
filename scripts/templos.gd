class_name Templos
extends RefCounted
## Los templos del juego, leídos de res://templos.json. Cada templo trae:
##   "nombre"          el título que se ve al terminarlo
##   "salas"           sus salas en orden (el nombre del archivo de salas/, sin .json)
##   "habilidades"     las que tiene el jugador en sus salas (una sala puede dar otras con su propia clave)
##   "capas_desde"     en qué sala del templo entra cada capa de la música
##   "coleccionables"  (opcional) cómo se llaman sus cuatro objetos opcionales
## El orden del juego es el de este archivo: templo tras templo, sala tras sala.

static var _lista: Array = []


static func lista() -> Array:
	if _lista.is_empty():
		_lista = JSON.parse_string(FileAccess.get_file_as_string("res://templos.json"))
	return _lista


## Las rutas de todas las salas, en el orden del juego.
static func rutas() -> Array[String]:
	var r: Array[String] = []
	for t in lista():
		for s in t["salas"]:
			r.append("res://salas/%s.json" % s)
	return r


## El templo de una sala. Una sala que todavía no está en templos.json (un boceto) cuenta como del río.
static func de(ruta: String) -> Dictionary:
	for t in lista():
		if ruta.get_file().get_basename() in t["salas"]:
			return t
	return {"nombre": "", "habilidades": ["traspasar", "reflejo"], "capas_desde": [0], "salas": []}


## Qué lugar ocupa la sala dentro de su templo (0 es la primera).
static func posicion(ruta: String) -> int:
	return de(ruta)["salas"].find(ruta.get_file().get_basename())
