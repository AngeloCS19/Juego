class_name Habilidad
extends RefCounted
## Una habilidad del jugador. Cada habilidad nueva (Reflejo, Giro...) es una subclase
## que implementa usar() y, si dura en el tiempo, en_curso().

var nombre: String
var disponible: bool  # false: se ve en la barra, pero el jugador todavía no la consigue


func _init(p_nombre := "", p_disponible := true) -> void:
	nombre = p_nombre
	disponible = p_disponible


## Lo que pasa al presionar Espacio con esta habilidad activa.
func usar(_sala: Sala) -> void:
	pass


## true mientras la habilidad sigue en efecto; en ese tiempo no se puede elegir otra.
func en_curso(_sala: Sala) -> bool:
	return false
