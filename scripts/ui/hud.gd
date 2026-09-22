extends CanvasLayer

## PLONPY - HUD 0.2

var progreso_label: Label
var mision_label: Label
var mensaje_label: Label
var mensaje_timer: float = 0.0
var refresh_timer: float = 0.0

func _node(path: String) -> Node:
	return get_node_or_null(path)

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _mission_manager() -> Node:
	return get_node_or_null("/root/MissionManager")

func _progression_manager() -> Node:
	return get_node_or_null("/root/ProgressionManager")

func _ready() -> void:
	progreso_label = _node("Panel/ProgresoLabel") as Label
	mision_label = _node("Panel/MisionLabel") as Label
	mensaje_label = _node("MensajeLabel") as Label

	if progreso_label == null or mision_label == null or mensaje_label == null:
		push_error("PLONPY: HUD incompleto.")
		return

	var progression := _progression_manager()
	var mission := _mission_manager()
	var game := _game_manager()

	if progression != null:
		if not progression.xp_changed.is_connected(_on_progression_changed):
			progression.xp_changed.connect(_on_progression_changed)
		if not progression.chispa_changed.is_connected(_on_chispa_changed):
			progression.chispa_changed.connect(_on_chispa_changed)
		if not progression.level_up.is_connected(_on_level_up):
			progression.level_up.connect(_on_level_up)

	if mission != null:
		if not mission.mission_started.is_connected(_on_mission_started):
			mission.mission_started.connect(_on_mission_started)
		if not mission.mission_completed.is_connected(_on_mission_completed):
			mission.mission_completed.connect(_on_mission_completed)
		if not mission.mission_progress_changed.is_connected(_on_mission_progress):
			mission.mission_progress_changed.connect(_on_mission_progress)

	if game != null and not game.state_changed.is_connected(_on_state_changed):
		game.state_changed.connect(_on_state_changed)

	if mission != null:
		mission.ensure_started()
	_refresh()
	call_deferred("_refresh")

func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer <= 0.0:
		refresh_timer = 0.25
		_refresh()

	if mensaje_timer > 0.0:
		mensaje_timer -= delta
		if mensaje_timer <= 0.0 and mensaje_label != null:
			mensaje_label.visible = false

func _refresh() -> void:
	var game := _game_manager()
	var mission := _mission_manager()
	if game == null:
		return

	if progreso_label != null:
		progreso_label.text = "PLONPY\n\nNúcleos: %d\nNivel: %d\nXP: %d\nCHISPA: %d" % [
			game.collected_nuclei.size(), game.nivel, game.xp, game.chispa
		]
	if mision_label != null and mission != null:
		if str(game.current_region) == "bosque_de_vetas":
			var raros := 0
			if game.has_nucleus("ojo_de_cristal"):
				raros += 1
			if game.has_nucleus("susurro_de_vyra"):
				raros += 1
			mision_label.text = "BOSQUE DE VETAS\nVegetación bioluminiscente y primeros Núcleos Raros.\n\nObjetivo regional: encuentra los 2 Núcleos Raros.\nProgreso: %d/2" % raros
		else:
			mision_label.text = mission.get_mission_text()

func _on_state_changed() -> void:
	_refresh()

func _on_progression_changed(_xp: int, _nivel: int) -> void:
	_refresh()

func _on_chispa_changed(_total: int) -> void:
	_refresh()

func _on_level_up(nuevo_nivel: int) -> void:
	show_message("⬆ Nivel %d alcanzado" % nuevo_nivel, 3.0)
	_refresh()

func _on_mission_started(_mission_id: String) -> void:
	_refresh()

func _on_mission_completed(mission_id: String) -> void:
	var mission := _mission_manager()
	var recompensa := ""
	if mission != null and mission.has_method("get_reward_text"):
		recompensa = "\n" + mission.get_reward_text(mission_id)
	show_message("✓ Misión %s completada%s" % [mission_id, recompensa], 4.0)
	_refresh()

func _on_mission_progress(_mission_id: String, _current: int, _total: int) -> void:
	_refresh()

func show_message(texto: String, duracion: float = 3.0) -> void:
	if mensaje_label == null:
		return
	mensaje_label.text = texto
	mensaje_label.visible = true
	mensaje_timer = duracion
