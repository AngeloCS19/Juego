class_name Transformacion
extends RefCounted
## Base de todas las transformaciones del plano espiritual.
## Cada templo agrega una subclase: Reflexion y Rotacion; después Traslacion y Homotecia.


## La marca que activa esta transformación: solo las piedras con esa marca tienen imagen.
## Es el nombre de la habilidad que la pone ("reflejo" para la reflexión).
var marca := ""


## Devuelve la casilla imagen de una casilla dada.
func aplicar(celda: Vector2i) -> Vector2i:
	return celda


## Dibuja el ancla visible de la transformación (eje, centro, vector...).
func dibujar(_lienzo: CanvasItem, _tam: float, _tamano_sala: Vector2i, _color: Color) -> void:
	pass


## Lo que el ancla muestra en el plano normal, encima de su casilla (el ángulo tallado en el altar).
## El río no necesita nada: se ve solo.
func dibujar_normal(_lienzo: CanvasItem, _tam: float) -> void:
	pass


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
			return Rotacion.new(Vector2i(int(datos["centro"][0]), int(datos["centro"][1])), int(datos["cuartos"]))
	push_error("Transformación desconocida: %s" % datos)
	return Transformacion.new()
