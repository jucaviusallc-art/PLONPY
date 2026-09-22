extends Node

## PLONPY - EXPLORATION MANAGER 0.2

signal discovery_registered(discovery_id: String, title: String)

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func register_discovery(discovery_id: String, title: String = "") -> bool:
	var game := _game_manager()
	if game == null or discovery_id.is_empty() or discovery_id in game.discovered_places:
		return false

	game.discovered_places.append(discovery_id)
	print("PLONPY: Descubrimiento registrado -> ", discovery_id)
	discovery_registered.emit(discovery_id, title)

	var mission := get_node_or_null("/root/MissionManager")
	if mission != null and mission.has_method("register_discovery_progress"):
		mission.register_discovery_progress(discovery_id)

	game.state_changed.emit()
	return true

func has_discovery(discovery_id: String) -> bool:
	var game := _game_manager()
	return game != null and discovery_id in game.discovered_places
