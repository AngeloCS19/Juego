class_name Traspasar
extends Habilidad
## Pasar del plano normal al espiritual y volver.


func _init() -> void:
	super("Traspasar")


func usar(sala: Sala) -> void:
	sala.cambiar_plano()


## Mientras estés en el plano espiritual, Traspasar sigue activa.
func en_curso(sala: Sala) -> bool:
	return sala.espiritual
