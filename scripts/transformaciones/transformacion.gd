class_name Transformacion
extends RefCounted
## Base de todas las transformaciones del plano espiritual.
## Cada templo agrega una subclase: Reflexion y Rotacion; después Traslacion y Homotecia.


## La marca que activa esta transformación: solo las piedras con esa marca tienen imagen.
## Es el nombre de la habilidad que la pone ("reflejo" para la reflexión).
var marca := ""

## Apoyo animado para quien no entiende el ancla (la flecha de la rueda). La sala lo maneja:
## guia_siempre viene del JSON ("flecha": true, en las primeras salas); guia es el reloj de la
## animación en segundos, o -1 si no hay que mostrarla.
var guia_siempre := false
var guia := -1.0


## Devuelve la casilla imagen de una casilla dada.
func aplicar(celda: Vector2i) -> Vector2i:
	return celda


## Dibuja el ancla visible de la transformación (eje, centro, vector...).
func dibujar(_lienzo: CanvasItem, _tam: float, _tamano_sala: Vector2i, _color: Color) -> void:
	pass


## Lo que el ancla pinta en el piso, debajo de piedras y jugador (la rueda de la rotación).
## k es el avance del viaje de las imágenes, de 0 a 1; vale 0 si no hay ninguna piedra con su marca.
## Devuelve true si pintó algo, para que la sala vuelva a dibujar encima muros, vacío y agua.
func dibujar_piso(_lienzo: CanvasItem, _tam: float, _k: float, _espiritual: bool) -> bool:
	return false


## Dónde se dibuja la imagen mientras viaja desde su piedra ("origen") hasta su lugar ("destino"),
## en píxeles; k va de 0 a 1. Por defecto en línea recta; una rotación viajará por su arco.
func viaje(origen: Vector2, destino: Vector2, k: float) -> Vector2:
	return origen.lerp(destino, k)


## Crea la transformación descrita en el JSON de una sala.
static func desde_datos(datos: Dictionary) -> Transformacion:
	match datos.get("tipo", ""):
		"reflexion":
			return Reflexion.new(datos["eje"], int(datos["valor"]))
		"rotacion":
			var rotacion := Rotacion.new(Vector2i(int(datos["centro"][0]), int(datos["centro"][1])), int(datos["cuartos"]))
			rotacion.radio = float(datos.get("radio", 0))
			rotacion.desde = int(datos.get("desde", 0))
			rotacion.guia_siempre = datos.get("flecha", false)
			return rotacion
	push_error("Transformación desconocida: %s" % datos)
	return Transformacion.new()
