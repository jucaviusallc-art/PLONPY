extends Node3D

## ============================================================
## PLONPY - COSTA DE CHISPA
## Coordinador de carga de escena - Fase 2
## ============================================================

func _ready() -> void:

	var cargando_partida := GameManager.is_loading_game

	# ------------------------------------------------------------
	# Solo establecer región/escena automáticamente cuando NO
	# estamos reconstruyendo una partida guardada.
	# ------------------------------------------------------------
	if not cargando_partida:
		GameManager.set_current_region("costa_de_chispa")
		GameManager.current_scene = scene_file_path

		print("PLONPY: Nueva instancia de Costa de Chispa.")
	else:
		print("PLONPY: Costa de Chispa reconstruida desde partida guardada.")

	# ------------------------------------------------------------
	# Restaurar posición del jugador únicamente durante una carga.
	# ------------------------------------------------------------
	var jugador := get_node_or_null("Jugador")

	if jugador != null and cargando_partida:
		if GameManager.has_saved_position:
			jugador.global_position = GameManager.player_spawn_position

			# Evitar que la velocidad anterior interfiera después
			# de la restauración.
			if jugador is CharacterBody3D:
				jugador.velocity = Vector3.ZERO

			print(
				"PLONPY: Posición del jugador restaurada -> ",
				jugador.global_position
			)

	# ------------------------------------------------------------
	# La escena ya está creada.
	# Finalizamos la segunda fase en el siguiente ciclo.
	# ------------------------------------------------------------
	call_deferred("_notificar_carga_lista")

	print("PLONPY: Costa de Chispa lista.")


func _notificar_carga_lista() -> void:

	var saver := get_node_or_null("/root/SaveManager")

	if saver != null and saver.has_method("finalizar_carga_escena"):
		saver.finalizar_carga_escena()
