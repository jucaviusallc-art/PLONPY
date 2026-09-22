extends Node3D

## ============================================================
## PLONPY — BOSQUE DE VETAS 0.5
## Entrada determinística y persistencia separada.
##
## 0.5:
## - Utiliza el estado explícito de transición del GameManager.
## - No intenta adivinar si viene de una transición.
## - No convierte el spawn de transición en guardado.
## - CONTINUAR / L sigue utilizando exclusivamente la posición
##   realmente guardada.
## ============================================================

const REGION_ID := "bosque_de_vetas"

const SPAWN_INICIAL := Vector3(
	0.0,
	1.0,
	5.0
)


func _ready() -> void:

	# ========================================================
	# CAPTURAR ESTADO ANTES DE MODIFICARLO
	# ========================================================

	var cargando_partida := (
		GameManager.is_loading_game
	)

	var entrada_por_transicion := (
		not cargando_partida
		and GameManager.hay_transicion_pendiente()
	)

	# ========================================================
	# IDENTIDAD DE LA REGIÓN
	# ========================================================

	GameManager.set_current_region(
		REGION_ID
	)

	# ========================================================
	# LOCALIZAR JUGADOR
	# ========================================================

	var jugador := get_node_or_null(
		"Jugador"
	) as CharacterBody3D

	if jugador == null:

		push_error(
			"PLONPY: No se encontró el nodo Jugador "
			+ "en Bosque de Vetas."
		)

		return

	# Asegurar visibilidad.
	jugador.visible = true

	# ========================================================
	# DETERMINAR ENTRADA
	# ========================================================

	if cargando_partida:

		# ----------------------------------------------------
		# CONTINUAR / L
		# ----------------------------------------------------

		if GameManager.has_saved_position:

			jugador.global_position = (
				GameManager.player_spawn_position
			)

			print(
				"PLONPY: Posición guardada restaurada -> ",
				jugador.global_position
			)

		else:

			jugador.global_position = (
				SPAWN_INICIAL
			)

			print(
				"PLONPY: Carga sin posición guardada. "
				+ "Usando spawn inicial -> ",
				SPAWN_INICIAL
			)

	elif entrada_por_transicion:

		# ----------------------------------------------------
		# ENTRADA DESDE COSTA DE CHISPA
		# ----------------------------------------------------

		var spawn_transicion := (
			GameManager.obtener_spawn_transicion()
		)

		jugador.global_position = (
			spawn_transicion
		)

		print(
			"PLONPY: Posición recibida desde transición -> ",
			jugador.global_position
		)

		# IMPORTANTE:
		# La transición es temporal.
		# No activa has_saved_position.
		GameManager.consumir_transicion()

		# Ahora que estamos dentro de Bosque, la escena actual
		# pasa a representar la región real.
		GameManager.current_scene = (
			scene_file_path
		)

	else:

		# ----------------------------------------------------
		# ENTRADA DIRECTA / NUEVA PARTIDA
		# ----------------------------------------------------

		jugador.global_position = (
			SPAWN_INICIAL
		)

		GameManager.current_scene = (
			scene_file_path
		)

		print(
			"PLONPY: Spawn inicial Bosque de Vetas -> ",
			SPAWN_INICIAL
		)

	# ========================================================
	# ESTADO FÍSICO INICIAL
	# ========================================================

	jugador.velocity = Vector3.ZERO

	jugador.floor_snap_length = 0.75

	jugador.apply_floor_snap()

	# ========================================================
	# FINALIZAR CARGA
	# ========================================================

	if cargando_partida:

		if SaveManager.has_method(
			"finalizar_carga_escena"
		):

			SaveManager.finalizar_carga_escena()

		else:

			GameManager.is_loading_game = false

	# ========================================================
	# INFORMACIÓN FINAL
	# ========================================================

	print(
		"PLONPY: Bosque de Vetas listo. Jugador -> ",
		jugador.global_position
	)


# ============================================================
# GUARDAR
# ============================================================

func guardar_partida() -> void:

	SaveManager.save_game()


# ============================================================
# CARGAR
# ============================================================

func cargar_partida() -> void:

	SaveManager.load_game()
