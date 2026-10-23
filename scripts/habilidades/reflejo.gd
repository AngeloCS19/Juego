class_name Reflejo
extends Habilidad
## Marca la piedra que el jugador tiene enfrente: su reflejo respecto al eje
## de la sala aparece en el plano espiritual. Usarla otra vez la desmarca.


func _init() -> void:
	super("Reflejo")


func usar(sala: Sala) -> void:
	sala.marcar_enfrente()
