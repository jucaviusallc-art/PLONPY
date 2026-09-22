extends Node

## ============================================================
## PLONPY - GAME MANAGER 0.3
## Estado central y persistente de la partida.
## ============================================================

signal nucleus_collected(nucleus_id: String)
signal region_changed(region_id: String)
signal state_changed()

const SAVE_SCHEMA_VERSION: int = 2

# Sesión / mundo
var game_started_state: bool = false
var current_region: String = "costa_de_chispa"
var current_scene: String = ""
var is_loading_game: bool = false # Transitorio: NO se persiste.

# Coleccionables / exploración
var collected_nuclei: Array = []
var discovered_places: Array = []

# Inventario genérico: item_id -> cantidad.
# Queda preparado para objetos, recursos y recompensas futuras.
var inventory: Dictionary = {}

# Progresión de Plonpy
var discovered_plonpy: Array = []
var current_plonpy: String = ""

# Misiones
var completed_missions: Array = []
var current_mission_id: String = ""
var mission_progress: Dictionary = {}

# Progresión
var nivel: int = 1
var xp: int = 0
var chispa: int = 0

# Posición persistente
var has_saved_position: bool = false
var player_spawn_position: Vector3 = Vector3(0.0, 1.0, 0.0)

func _ready() -> void:
	print("PLONPY: GameManager 0.3 inicializado correctamente.")

func set_current_region(region_id: String) -> void:
	if region_id.is_empty() or current_region == region_id:
		return
	current_region = region_id
	region_changed.emit(region_id)
	state_changed.emit()

func register_nucleus(nucleus_id: String) -> bool:
	if nucleus_id.is_empty() or nucleus_id in collected_nuclei:
		return false
	collected_nuclei.append(nucleus_id)
	print("PLONPY: Núcleo registrado -> ", nucleus_id)
	nucleus_collected.emit(nucleus_id)
	state_changed.emit()
	return true

func has_nucleus(nucleus_id: String) -> bool:
	return nucleus_id in collected_nuclei

func start_game() -> void:
	game_started_state = true
	print("PLONPY: Partida iniciada.")
	state_changed.emit()

func set_player_position(pos: Vector3) -> void:
	player_spawn_position = pos
	has_saved_position = true

func add_inventory_item(item_id: String, cantidad: int = 1) -> bool:
	if item_id.is_empty() or cantidad <= 0:
		return false
	inventory[item_id] = int(inventory.get(item_id, 0)) + cantidad
	state_changed.emit()
	return true

func remove_inventory_item(item_id: String, cantidad: int = 1) -> bool:
	if item_id.is_empty() or cantidad <= 0:
		return false
	var actual := int(inventory.get(item_id, 0))
	if actual < cantidad:
		return false
	actual -= cantidad
	if actual <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = actual
	state_changed.emit()
	return true

func get_inventory_quantity(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func get_game_state() -> Dictionary:
	# Se devuelve una copia profunda para impedir que un Manager externo
	# modifique accidentalmente el estado mientras se está serializando.
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"game_started_state": game_started_state,
		"current_region": current_region,
		"current_scene": current_scene,
		"collected_nuclei": collected_nuclei.duplicate(),
		"discovered_places": discovered_places.duplicate(),
		"inventory": inventory.duplicate(true),
		"discovered_plonpy": discovered_plonpy.duplicate(),
		"current_plonpy": current_plonpy,
		"completed_missions": completed_missions.duplicate(),
		"current_mission_id": current_mission_id,
		"mission_progress": mission_progress.duplicate(true),
		"nivel": nivel,
		"xp": xp,
		"chispa": chispa,
		"has_saved_position": has_saved_position,
		"player_spawn_position": [
			player_spawn_position.x,
			player_spawn_position.y,
			player_spawn_position.z
		]
	}

func apply_game_state(state: Dictionary) -> bool:
	if state.is_empty():
		return false

	game_started_state = bool(state.get("game_started_state", true))
	current_region = str(state.get("current_region", "costa_de_chispa"))
	current_scene = str(state.get("current_scene", ""))

	collected_nuclei = _safe_string_array(state.get("collected_nuclei", []))
	discovered_places = _safe_string_array(state.get("discovered_places", []))
	discovered_plonpy = _safe_string_array(state.get("discovered_plonpy", []))
	completed_missions = _safe_string_array(state.get("completed_missions", []))

	var inventory_state = state.get("inventory", {})
	inventory = inventory_state.duplicate(true) if inventory_state is Dictionary else {}

	current_plonpy = str(state.get("current_plonpy", ""))
	current_mission_id = str(state.get("current_mission_id", ""))

	var mission_state = state.get("mission_progress", {})
	mission_progress = mission_state.duplicate(true) if mission_state is Dictionary else {}

	nivel = max(1, int(state.get("nivel", 1)))
	xp = max(0, int(state.get("xp", 0)))
	chispa = max(0, int(state.get("chispa", 0)))
	has_saved_position = bool(state.get("has_saved_position", false))

	var pos_array = state.get("player_spawn_position", [0.0, 1.0, 0.0])
	if pos_array is Array and pos_array.size() >= 3:
		player_spawn_position = Vector3(
			float(pos_array[0]),
			float(pos_array[1]),
			float(pos_array[2])
		)
	else:
		player_spawn_position = Vector3(0.0, 1.0, 0.0)

	state_changed.emit()
	print("PLONPY: Estado de partida restaurado.")
	return true

func _safe_string_array(value) -> Array:
	if not value is Array:
		return []
	var result: Array = []
	for item in value:
		result.append(str(item))
	return result

func reset_game_state() -> void:
	game_started_state = false
	current_region = "costa_de_chispa"
	current_scene = ""
	is_loading_game = false
	collected_nuclei.clear()
	discovered_places.clear()
	inventory.clear()
	discovered_plonpy.clear()
	current_plonpy = ""
	completed_missions.clear()
	current_mission_id = ""
	mission_progress.clear()
	nivel = 1
	xp = 0
	chispa = 0
	has_saved_position = false
	player_spawn_position = Vector3(0.0, 1.0, 0.0)
	state_changed.emit()
	print("PLONPY: Nueva partida preparada.")
