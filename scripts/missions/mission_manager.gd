extends Node

## ============================================================
## PLONPY - MISSION MANAGER 0.4 (Con sincronización retroactiva)
## ============================================================

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_progress_changed(mission_id: String, current: int, total: int)

const M001: String = "M001"
const M002: String = "M002"
const M003: String = "M003"

const RECOMPENSAS: Dictionary = {
	M001: {"xp": 50, "chispa": 25},
	M002: {"xp": 100, "chispa": 50},
	M003: {"xp": 150, "chispa": 75}
}

const MISIONES: Dictionary = {
	M001: {
		"title": "Despertar",
		"objective": "Explora la Costa de Chispa y comienza tu viaje.",
		"total": 1
	},
	M002: {
		"title": "La Llamada",
		"objective": "Acércate a la Chispa Primigenia.",
		"total": 1
	},
	M003: {
		"title": "Tres luces azules",
		"objective": "Descubre los tres elementos clave de la costa.",
		"total": 3
	}
}

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	var game := _game_manager()
	if game != null and not game.nucleus_collected.is_connected(_on_nucleus_collected):
		game.nucleus_collected.connect(_on_nucleus_collected)
	call_deferred("ensure_started")
	print("PLONPY: MissionManager 0.4 iniciado correctamente.")

func ensure_started() -> void:
	var game := _game_manager()
	if game == null:
		return
	if not game.current_mission_id.is_empty() and MISIONES.has(game.current_mission_id):
		return
	if M001 not in game.completed_missions:
		start_mission(M001)
	elif M002 not in game.completed_missions:
		start_mission(M002)
	elif M003 not in game.completed_missions:
		start_mission(M003)
	else:
		game.current_mission_id = ""
		game.state_changed.emit()

func start_mission(mission_id: String) -> void:
	var game := _game_manager()
	if game == null or not MISIONES.has(mission_id):
		return
	if mission_id in game.completed_missions:
		return
	game.current_mission_id = mission_id
	if not game.mission_progress.has(mission_id):
		game.mission_progress[mission_id] = 0

	# Sincronización automática retroactiva para M003
	if mission_id == M003:
		var count := 0
		for d_id in ["eco_de_costa", "gota_de_luz", "burbuja_de_energia"]:
			if game.discovered_places.has(d_id):
				count += 1
		game.mission_progress[M003] = count
		if count >= get_current_total():
			call_deferred("complete_mission", M003)

	print("PLONPY: Misión activa -> ", mission_id, " | ", get_current_title())
	mission_started.emit(mission_id)
	mission_progress_changed.emit(mission_id, get_current_progress(), get_current_total())
	game.state_changed.emit()

func notify_player_moved() -> void:
	var game := _game_manager()
	if game == null or game.current_mission_id != M001:
		return
	set_progress(M001, 1)
	complete_mission(M001)

func _on_nucleus_collected(nucleus_id: String) -> void:
	var game := _game_manager()
	if game == null:
		return
	if game.current_mission_id == M002 and nucleus_id == "chispa_primigenia":
		set_progress(M002, 1)
		complete_mission(M002)

func register_discovery_progress(_discovery_id: String) -> void:
	var game := _game_manager()
	if game == null or game.current_mission_id != M003:
		return
	var current: int = int(game.mission_progress.get(M003, 0))
	current = min(current + 1, get_current_total())
	game.mission_progress[M003] = current
	mission_progress_changed.emit(M003, current, get_current_total())
	game.state_changed.emit()
	if current >= get_current_total():
		complete_mission(M003)

func set_progress(mission_id: String, value: int) -> void:
	var game := _game_manager()
	if game == null or not MISIONES.has(mission_id):
		return
	var total: int = int(MISIONES[mission_id]["total"])
	var current: int = clamp(value, 0, total)
	game.mission_progress[mission_id] = current
	mission_progress_changed.emit(mission_id, current, total)
	game.state_changed.emit()

func complete_mission(mission_id: String) -> void:
	var game := _game_manager()
	if game == null or mission_id.is_empty() or mission_id in game.completed_missions:
		return
	if not MISIONES.has(mission_id):
		return
	game.mission_progress[mission_id] = get_current_total_for(mission_id)
	game.completed_missions.append(mission_id)

	var reward: Dictionary = RECOMPENSAS.get(mission_id, {})
	var progression := get_node_or_null("/root/ProgressionManager")
	if progression != null and progression.has_method("give_reward"):
		progression.give_reward(int(reward.get("xp", 0)), int(reward.get("chispa", 0)))

	print("PLONPY: Misión completada -> ", mission_id)
	mission_completed.emit(mission_id)

	match mission_id:
		M001:
			start_mission(M002)
		M002:
			start_mission(M003)
		M003:
			game.current_mission_id = ""

	game.state_changed.emit()

func get_save_state() -> Dictionary:
	var game := _game_manager()
	if game == null:
		return {"current_mission_id": "", "mission_progress": {}}
	return {
		"current_mission_id": game.current_mission_id,
		"mission_progress": game.mission_progress.duplicate(true)
	}

func apply_save_state(state: Dictionary) -> void:
	var game := _game_manager()
	if game == null or state.is_empty():
		return
	game.current_mission_id = str(state.get("current_mission_id", game.current_mission_id))
	var progress = state.get("mission_progress", game.mission_progress)
	if progress is Dictionary:
		game.mission_progress = progress.duplicate(true)

func get_current_title() -> String:
	var game := _game_manager()
	if game == null or game.current_mission_id.is_empty():
		return "Historia inicial completada"
	return str(MISIONES[game.current_mission_id]["title"])

func get_current_objective() -> String:
	var game := _game_manager()
	if game == null or game.current_mission_id.is_empty():
		return "Explora libremente la Costa de Chispa."
	return str(MISIONES[game.current_mission_id]["objective"])

func get_current_progress() -> int:
	var game := _game_manager()
	if game == null or game.current_mission_id.is_empty():
		return 0
	return int(game.mission_progress.get(game.current_mission_id, 0))

func get_current_total() -> int:
	var game := _game_manager()
	if game == null or game.current_mission_id.is_empty():
		return 0
	return get_current_total_for(game.current_mission_id)

func get_current_total_for(mission_id: String) -> int:
	if not MISIONES.has(mission_id):
		return 0
	return int(MISIONES[mission_id]["total"])

func get_reward_text(mission_id: String) -> String:
	var reward: Dictionary = RECOMPENSAS.get(mission_id, {})
	return "Recompensa: +%d XP +%d CHISPA" % [
		int(reward.get("xp", 0)),
		int(reward.get("chispa", 0))
	]

func get_mission_text() -> String:
	var game := _game_manager()
	if game == null or game.current_mission_id.is_empty():
		return "HISTORIA INICIAL COMPLETADA\nExplora libremente la Costa de Chispa."
	return "MISIÓN %s — %s\n%s\nProgreso: %d/%d" % [
		game.current_mission_id,
		get_current_title(),
		get_current_objective(),
		get_current_progress(),
		get_current_total()
	]
