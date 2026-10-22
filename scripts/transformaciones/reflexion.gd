class_name Reflexion
extends Transformacion
## Reflexión respecto a un eje que pasa por el centro de una fila, columna o diagonal de casillas.
##   "horizontal":   eje y = valor
##   "vertical":     eje x = valor
##   "diagonal":     eje y = x + valor
##   "antidiagonal": eje x + y = valor

var eje: String
var valor: int


func _init(p_eje: String, p_valor: int) -> void:
	eje = p_eje
	valor = p_valor


func aplicar(c: Vector2i) -> Vector2i:
	match eje:
		"horizontal":
			return Vector2i(c.x, 2 * valor - c.y)
		"vertical":
			return Vector2i(2 * valor - c.x, c.y)
		"diagonal":
			return Vector2i(c.y - valor, c.x + valor)
		"antidiagonal":
			return Vector2i(valor - c.y, valor - c.x)
	push_error("Eje desconocido: %s" % eje)
	return c


func dibujar(lienzo: CanvasItem, tam: float, tamano_sala: Vector2i, color: Color) -> void:
	var ancho := tamano_sala.x * tam
	var alto := tamano_sala.y * tam
	var m := (valor + 0.5) * tam  # centro de la fila o columna del eje
	var a: Vector2
	var b: Vector2
	match eje:
		"horizontal":
			a = Vector2(0, m)
			b = Vector2(ancho, m)
		"vertical":
			a = Vector2(m, 0)
			b = Vector2(m, alto)
		"diagonal":
			a = Vector2(-valor * tam, 0)
			b = Vector2(alto - valor * tam, alto)
		"antidiagonal":
			a = Vector2((valor + 1) * tam, 0)
			b = Vector2((valor + 1) * tam - alto, alto)
	lienzo.draw_dashed_line(a, b, color, 3.0, 10.0)
