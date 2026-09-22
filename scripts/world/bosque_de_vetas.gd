extends Node3D

## ============================================================
## PLONPY — BOSQUE DE VETAS 0.4
## Entrada, transición y persistencia de posición
## ============================================================
##
## Reglas:
## 1. CONTINUAR / L usa la posición realmente guardada.
## 2. Una transición desde otra región usa el spawn preparado
##    por region_transition.gd.
## 3. Una entrada directa o una nueva partida usa SPAWN_INICIAL.
## 4. El spawn de transición NO se convierte en guardado.
## 5. El guardado en disco continúa siendo exclusivamente con G.

const REGION_ID := "bosque_de_vetas"
const SPAWN_INICIAL := Vector3(0.0, 1.0, 5.0)


func _ready() -> void:
	# ------------------------------------------------------------
	# CAPTURAR EL TIPO DE ENTRADA ANTES DE MODIFICAR EL ESTADO
	# ------------------------------------------------------------
	var cargando_partida := GameManager.is_loading_game
	var entrada_por_transicion := _hay_transicion_pendiente(cargando_partida)

	# ------------------------------------------------------------
	# IDENTIDAD DE LA REGIÓN
	# ------------------------------------------------------------
	GameManager.set_current_region(REGION_ID)

	# Durante una carga la escena guardada ya fue restaurada por
	# SaveManager. No la sustituimos aquí.
	if not cargando_partida:
		GameManager.current_scene = scene_file_path

	# ------------------------------------------------------------
	# LOCALIZAR JUGADOR
	# ------------------------------------------------------------
	var jugador := get_node_or_null("Jugador") as CharacterBody3D

	if jugador == null:
		push_error(
			"PLONPY: No se encontró el nodo Jugador en Bosque de Vetas."
		)
		return

	# Asegurar que el personaje sea visible en esta región.
	jugador.visible = true

	# ------------------------------------------------------------
	# DETERMINAR POSICIÓN DE ENTRADA
	# ------------------------------------------------------------
	if cargando_partida and GameManager.has_saved_position:

		# ========================================================
		# CONTINUAR / L
		# ========================================================
		jugador.global_position = GameManager.player_spawn_position

		print(
			"PLONPY: Posición guardada restaurada -> ",
			jugador.global_position
		)

	elif entrada_por_transicion:

		# ========================================================
		# TRANSICIÓN DESDE COSTA DE CHISPA
		# ========================================================
		# region_transition.gd prepara esta posición antes de
		# cambiar de escena.
		#
		# Importante:
		# Esta posición NO representa un guardado de partida.
		# Por eso no activamos has_saved_position.
		jugador.global_position = GameManager.player_spawn_position

		print(
			"PLONPY: Posición recibida desde transición -> ",
			jugador.global_position
		)

	else:

		# ========================================================
		# NUEVA PARTIDA / ENTRADA DIRECTA
		# ========================================================
		jugador.global_position = SPAWN_INICIAL

		print(
			"PLONPY: Spawn inicial Bosque de Vetas -> ",
			SPAWN_INICIAL
		)

	# ------------------------------------------------------------
	# ESTADO FÍSICO INICIAL
	# ------------------------------------------------------------
	jugador.velocity = Vector3.ZERO
	jugador.floor_snap_length = 0.75
	jugador.apply_floor_snap()

	# ------------------------------------------------------------
	# FINALIZAR CARGA
	# ------------------------------------------------------------
	if cargando_partida:
		if SaveManager.has_method("finalizar_carga_escena"):
			SaveManager.finalizar_carga_escena()
		else:
			GameManager.is_loading_game = false

	print(
		"PLONPY: Bosque de Vetas listo. Jugador -> ",
		jugador.global_position
	)


func _hay_transicion_pendiente(cargando_partida: bool) -> bool:
	if cargando_partida:
		return false

	# region_transition.gd establece current_scene antes de
	# cambiar a esta escena.
	#
	# Dependiendo de cómo Godot serialice el recurso, puede
	# recibirse como ruta res:// o como UID uid://.
	var escena_pendiente: String = GameManager.current_scene

	if escena_pendiente.is_empty():
		return false

	if escena_pendiente == scene_file_path:
		return true

	if escena_pendiente.begins_with("uid://"):
		return true

	return false


# ============================================================
# GUARDAR PARTIDA
# ============================================================

func guardar_partida() -> void:
	SaveManager.save_game()


# ============================================================
# CARGAR PARTIDA
# ============================================================

func cargar_partida() -> void:
	SaveManager.load_game()
