extends Node

## ============================================================
## PLONPY - SAVE MANAGER 1.7.2
## Persistencia robusta con carga atómica de dos fases y
## sincronización estricta de reconstrucción de escena.
##
## 1.7.2:
## - Captura la posición REAL del Jugador al presionar G.
## - Mantiene intacto el resto del sistema de guardado/carga.
## ============================================================

const SAVE_PATH: String = "user://plonpy_save.json"
const BACKUP_PATH: String = "user://plonpy_save.bak.json"
const SAVE_SCHEMA_VERSION: int = 2

signal game_saved()
signal game_loaded()
signal save_validation_failed(reason: String)

var is_loading: bool = false


# ============================================================
# INICIO
# ============================================================

func _ready() -> void:
	print("PLONPY: SaveManager 1.7.2 iniciado.")

	if has_save():
		print("PLONPY: Partida guardada disponible.")
		print("PLONPY: La partida NO se cargará automáticamente.")
	else:
		print("PLONPY: No existe partida guardada.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("guardar_partida"):
		print("PLONPY: Tecla G detectada.")
		save_game()
		return

	if event.is_action_pressed("cargar_partida"):
		print("PLONPY: Tecla L detectada.")
		load_game()
		return


# ============================================================
# GUARDAR PARTIDA
# ============================================================

func save_game() -> bool:
	if is_loading:
		print("PLONPY: Guardado omitido mientras se procesa otra operación.")
		return false

	var escena_actual := get_tree().current_scene

	if escena_actual != null and not escena_actual.scene_file_path.is_empty():
		GameManager.current_scene = escena_actual.scene_file_path

	# ------------------------------------------------------------
	# 1.7.2 - CAPTURAR POSICIÓN REAL DEL JUGADOR
	# ------------------------------------------------------------
	# La posición se toma directamente del nodo Jugador en el
	# momento exacto en que se presiona G.
	if escena_actual != null:
		var jugador := escena_actual.get_node_or_null("Jugador")

		if jugador != null:
			GameManager.set_player_position(jugador.global_position)
			print(
				"PLONPY: Posición del jugador capturada -> ",
				jugador.global_position
			)
		else:
			print(
				"PLONPY: Advertencia -> No se encontró el nodo Jugador. "
				+ "Se conservará la última posición registrada."
			)

	var game_state: Dictionary = GameManager.get_game_state()

	var mission_state: Dictionary = {}
	var mission_manager := get_node_or_null("/root/MissionManager")

	if mission_manager != null and mission_manager.has_method("get_save_state"):
		mission_state = mission_manager.get_save_state()

	var state: Dictionary = {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"game": game_state,
		"missions": mission_state
	}

	var validation_error := _validate_state_dictionary(state)

	if not validation_error.is_empty():
		push_error("PLONPY: Guardado rechazado: " + validation_error)
		save_validation_failed.emit(validation_error)
		return false

	var json_string := JSON.stringify(state, "\t")
	var temp_path := SAVE_PATH + ".tmp"

	var file := FileAccess.open(temp_path, FileAccess.WRITE)

	if file == null:
		push_error("PLONPY: No se pudo abrir el temporal de guardado.")
		return false

	file.store_string(json_string)
	file.flush()
	file.close()

	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(BACKUP_PATH)
			)

		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(SAVE_PATH),
			ProjectSettings.globalize_path(BACKUP_PATH)
		)

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(SAVE_PATH)
	)

	if rename_error != OK:
		push_error("PLONPY: No se pudo finalizar el archivo de guardado.")

		if (
			not FileAccess.file_exists(SAVE_PATH)
			and FileAccess.file_exists(BACKUP_PATH)
		):
			DirAccess.rename_absolute(
				ProjectSettings.globalize_path(BACKUP_PATH),
				ProjectSettings.globalize_path(SAVE_PATH)
			)

		return false

	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(BACKUP_PATH)
		)

	print("PLONPY: Partida guardada correctamente.")
	print("PLONPY: Archivo -> ", SAVE_PATH)

	print(
		"PLONPY: Guardado validado -> núcleos=%d | descubrimientos=%d | misiones=%d | inventario=%d"
		% [
			game_state["collected_nuclei"].size(),
			game_state["discovered_places"].size(),
			game_state["completed_missions"].size(),
			game_state["inventory"].size()
		]
	)

	game_saved.emit()
	return true


# ============================================================
# CARGAR PARTIDA
# Fase 1: Restauración de Datos y Cambio de Escena
# ============================================================

func load_game() -> bool:
	if is_loading:
		print("PLONPY: Carga ignorada; ya existe una operación en proceso.")
		return false

	is_loading = true
	GameManager.is_loading_game = true

	print("PLONPY: Cargando partida...")

	var state := _read_save_file(SAVE_PATH)

	if state.is_empty() and FileAccess.file_exists(BACKUP_PATH):
		print("PLONPY: Guardado principal inválido. Intentando backup...")
		state = _read_save_file(BACKUP_PATH)

	if state.is_empty():
		print("PLONPY: No existe una partida guardada válida.")
		is_loading = false
		GameManager.is_loading_game = false
		return false

	var validation_error := _validate_state_dictionary(state)

	if not validation_error.is_empty():
		push_error("PLONPY: Guardado inválido: " + validation_error)
		save_validation_failed.emit(validation_error)

		is_loading = false
		GameManager.is_loading_game = false
		return false

	# ------------------------------------------------------------
	# RESTAURAR GAMEMANAGER
	# ------------------------------------------------------------

	var game_state = state.get("game", {})

	if game_state is Dictionary:
		if not GameManager.apply_game_state(game_state):
			is_loading = false
			GameManager.is_loading_game = false
			return false

	print("PLONPY: Estado GameManager restaurado.")

	# ------------------------------------------------------------
	# RESTAURAR MISSIONMANAGER
	# ------------------------------------------------------------

	var mission_manager := get_node_or_null("/root/MissionManager")
	var mission_state = state.get("missions", {})

	if (
		mission_manager != null
		and mission_state is Dictionary
		and mission_manager.has_method("apply_save_state")
	):
		mission_manager.apply_save_state(mission_state)

	print("PLONPY: Estado MissionManager restaurado.")

	# ------------------------------------------------------------
	# VALIDACIÓN
	# ------------------------------------------------------------

	var post_error := _validate_runtime_state()

	if not post_error.is_empty():
		push_error(
			"PLONPY: Estado restaurado inconsistente: "
			+ post_error
		)

		is_loading = false
		GameManager.is_loading_game = false

		save_validation_failed.emit(post_error)
		return false

	# ------------------------------------------------------------
	# INFORMACIÓN RESTAURADA
	# ------------------------------------------------------------

	print("PLONPY: Estado de partida restaurado correctamente.")
	print("PLONPY: Región -> ", GameManager.current_region)
	print("PLONPY: Escena guardada -> ", GameManager.current_scene)
	print("PLONPY: Posición guardada -> ", GameManager.player_spawn_position)

	print(
		"PLONPY: XP -> ",
		GameManager.xp,
		" | Nivel -> ",
		GameManager.nivel,
		" | CHISPA -> ",
		GameManager.chispa
	)

	# Los datos ya fueron restaurados.
	# La escena todavía NO ha terminado de reconstruirse.
	game_loaded.emit()

	call_deferred("_recargar_escena_cargada")

	return true


# ============================================================
# LECTURA DE ARCHIVOS Y VALIDACIONES
# ============================================================

func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	if content.is_empty():
		return {}

	var json := JSON.new()

	if json.parse(content) != OK:
		return {}

	var data = json.data

	if not data is Dictionary:
		return {}

	# Compatibilidad con formato anterior
	if data.has("current_region") and not data.has("game"):
		return {
			"save_schema_version": 1,
			"saved_at_unix": 0,
			"game": data,
			"missions": {
				"current_mission_id": data.get("current_mission_id", ""),
				"mission_progress": data.get("mission_progress", {})
			}
		}

	return data


func _validate_state_dictionary(state: Dictionary) -> String:
	if not state.has("game") or not state.has("missions"):
		return "estructura de bloques incompleta"

	if not state["game"] is Dictionary or not state["missions"] is Dictionary:
		return "tipos de bloques inválidos"

	var game: Dictionary = state["game"]

	var required_keys := [
		"current_region",
		"current_scene",
		"collected_nuclei",
		"discovered_places",
		"inventory",
		"discovered_plonpy",
		"current_plonpy",
		"completed_missions",
		"nivel",
		"xp",
		"chispa",
		"has_saved_position",
		"player_spawn_position"
	]

	for key in required_keys:
		if not game.has(key):
			return "falta la variable '" + key + "'"

	if (
		not game["player_spawn_position"] is Array
		or game["player_spawn_position"].size() < 3
	):
		return "posición inválida"

	var missions: Dictionary = state["missions"]

	if (
		not missions.has("current_mission_id")
		or not missions.has("mission_progress")
	):
		return "bloque de misiones incompleto"

	return ""


func _validate_runtime_state() -> String:
	var game_state: Dictionary = GameManager.get_game_state()

	var missions_state: Dictionary = {}
	var mission_manager := get_node_or_null("/root/MissionManager")

	if mission_manager != null and mission_manager.has_method("get_save_state"):
		missions_state = mission_manager.get_save_state()
	else:
		missions_state = {
			"current_mission_id": GameManager.current_mission_id,
			"mission_progress": GameManager.mission_progress
		}

	var wrapper := {
		"game": game_state,
		"missions": missions_state
	}

	return _validate_state_dictionary(wrapper)


# ============================================================
# RECONSTRUCCIÓN DE ESCENA
# Fase 2
# ============================================================

func _recargar_escena_cargada() -> void:
	var escena_actual := get_tree().current_scene

	if escena_actual == null:
		print("PLONPY: No existe escena actual para restaurar.")
		is_loading = false
		GameManager.is_loading_game = false
		return

	var escena_guardada := GameManager.current_scene

	print("PLONPY: Recargando escena guardada...")
	print("PLONPY: Escena objetivo -> ", escena_guardada)

	if (
		not escena_guardada.is_empty()
		and ResourceLoader.exists(escena_guardada)
		and escena_actual.scene_file_path != escena_guardada
	):
		print("PLONPY: Cambiando a escena guardada.")

		var error := get_tree().change_scene_to_file(escena_guardada)

		if error != OK:
			push_error(
				"PLONPY: Error cambiando a escena -> "
				+ str(error)
			)

			is_loading = false
			GameManager.is_loading_game = false

		return

	print("PLONPY: Recargando escena actual.")
	get_tree().reload_current_scene()


func finalizar_carga_escena() -> void:
	if not is_loading:
		return

	print("PLONPY: Escena reconstruida correctamente.")

	is_loading = false
	GameManager.is_loading_game = false

	print("PLONPY: Carga completada. Estado estabilizado.")


# ============================================================
# UTILIDADES Y NUEVA PARTIDA
# ============================================================

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func validate_save_file() -> bool:
	var state := _read_save_file(SAVE_PATH)

	if state.is_empty():
		return false

	return _validate_state_dictionary(state).is_empty()


func delete_save() -> bool:
	var ok := true

	for path in [SAVE_PATH, BACKUP_PATH, SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			if (
				DirAccess.remove_absolute(
					ProjectSettings.globalize_path(path)
				) != OK
			):
				ok = false

	if ok:
		print("PLONPY: Partida eliminada correctamente.")

	return ok


func new_game() -> void:
	is_loading = false
	GameManager.is_loading_game = false

	print("PLONPY: INICIANDO NUEVA PARTIDA...")

	GameManager.reset_game_state()
	delete_save()

	var mission := get_node_or_null("/root/MissionManager")

	if mission != null and mission.has_method("ensure_started"):
		mission.ensure_started()

	get_tree().reload_current_scene()

	print("PLONPY: Nueva partida iniciada.")
