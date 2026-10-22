class_name Transformacion
extends RefCounted
## Base de todas las transformaciones del plano espiritual.
## Cada templo agrega una subclase: hoy Reflexion; después Rotacion, Traslacion, Homotecia.


## Devuelve la casilla imagen de una casilla dada.
func aplicar(celda: Vector2i) -> Vector2i:
	return celda


## Dibuja el ancla visible de la transformación (eje, centro, vector...).
func dibujar(_lienzo: CanvasItem, _tam: float, _tamano_sala: Vector2i, _color: Color) -> void:
	pass


## Crea la transformación descrita en el JSON de una sala.
static func desde_datos(datos: Dictionary) -> Transformacion:
	match datos.get("tipo", ""):
		"reflexion":
			return Reflexion.new(datos["eje"], int(datos["valor"]))
	push_error("Transformación desconocida: %s" % datos)
	return Transformacion.new()
