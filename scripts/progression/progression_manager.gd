extends Node

## PLONPY - PROGRESSION MANAGER 0.2
## Administra XP, niveles y CHISPA.

signal xp_changed(xp: int, nivel: int)
signal chispa_changed(total: int)
signal level_up(nuevo_nivel: int)

const XP_POR_NIVEL: int = 100

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func add_xp(cantidad: int) -> void:
	var game := _game_manager()
	if game == null or cantidad <= 0:
		return

	var xp_actual: int = int(game.xp) + cantidad
	game.xp = xp_actual

	var nivel_anterior: int = max(1, int(game.nivel))
	var nuevo_nivel: int = int(xp_actual / XP_POR_NIVEL) + 1
	game.nivel = nuevo_nivel

	print("PLONPY: +", cantidad, " XP -> Total: ", xp_actual, " | Nivel: ", nuevo_nivel)
	xp_changed.emit(xp_actual, nuevo_nivel)
	game.state_changed.emit()

	if nuevo_nivel > nivel_anterior:
		level_up.emit(nuevo_nivel)

func add_chispa(cantidad: int) -> void:
	var game := _game_manager()
	if game == null or cantidad <= 0:
		return

	var chispa_actual: int = int(game.chispa) + cantidad
	game.chispa = chispa_actual
	print("PLONPY: +", cantidad, " CHISPA -> Total: ", chispa_actual)
	chispa_changed.emit(chispa_actual)
	game.state_changed.emit()

func give_reward(xp: int, chispa: int) -> void:
	if xp > 0:
		add_xp(xp)
	if chispa > 0:
		add_chispa(chispa)
