class_name Giro
extends Habilidad
## Marca la piedra que el jugador tiene enfrente: su imagen, girada alrededor del altar
## de la sala, aparece en el plano espiritual. Usarla otra vez la desmarca.


func _init() -> void:
	super("Giro")


func usar(sala: Sala) -> void:
	sala.marcar_enfrente("giro")
