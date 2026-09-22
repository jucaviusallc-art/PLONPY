extends Area3D

## ============================================================
## PLONPY — TRANSICIÓN ENTRE REGIONES
## BLOQUE 03.1
## ============================================================

@export_file("*.tscn") var destination_scene: String = ""
@export var destination_region: String = ""
@export var destination_spawn_position: Vector3 = Vector3.ZERO

var _transition_used: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	print(
		"PLONPY: Transición preparada -> ",
		destination_region,
		" | escena -> ",
		destination_scene
	)


func _on_body_entered(body: Node3D) -> void:
	if _transition_used:
		return

	if not body.name == "Jugador":
		return

	if destination_scene.is_empty():
		push_error(
			"PLONPY: Transición sin escena destino configurada."
		)
		return

	_transition_used = true

	print(
		"PLONPY: Jugador entrando en transición -> ",
		destination_region
	)

	_preparar_transicion()

	get_tree().change_scene_to_file(destination_scene)


func _preparar_transicion() -> void:
	GameManager.current_region = destination_region
	GameManager.current_scene = destination_scene

	# La posición de entrada pertenece a la transición,
	# NO constituye un guardado de partida.
	GameManager.player_spawn_position = destination_spawn_position

	print(
		"PLONPY: Región destino -> ",
		GameManager.current_region
	)

	print(
		"PLONPY: Spawn destino -> ",
		GameManager.player_spawn_position
	)
