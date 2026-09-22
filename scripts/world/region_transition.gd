extends Area3D

## ============================================================
## PLONPY — TRANSICIÓN ENTRE REGIONES
## BLOQUE 03.2
##
## Funciones:
## - Comprueba desbloqueo de Bosque mediante M003.
## - Prepara una transición temporal.
## - NO modifica el guardado de partida.
## - Entrega un spawn explícito a la región destino.
## ============================================================

@export_file("*.tscn") var destination_scene: String = ""
@export var destination_region: String = ""
@export var destination_spawn_position: Vector3 = Vector3.ZERO

var _transition_used: bool = false


func _ready() -> void:

	body_entered.connect(
		_on_body_entered
	)

	print(
		"PLONPY: Transición preparada -> ",
		destination_region,
		" | escena -> ",
		destination_scene
	)


func _on_body_entered(body: Node3D) -> void:

	if _transition_used:
		return

	if body.name != "Jugador":
		return

	# --------------------------------------------------------
	# BLOQUEO POR PROGRESIÓN
	# --------------------------------------------------------

	if destination_region == "bosque_de_vetas":

		if not _bosque_desbloqueado():

			print(
				"PLONPY: Bosque de Vetas todavía bloqueado. "
				+ "Se requiere M003."
			)

			return

	# --------------------------------------------------------
	# VALIDAR DESTINO
	# --------------------------------------------------------

	if destination_scene.is_empty():

		push_error(
			"PLONPY: Transición sin escena destino configurada."
		)

		return

	# --------------------------------------------------------
	# ACTIVAR TRANSICIÓN
	# --------------------------------------------------------

	_transition_used = true

	print(
		"PLONPY: Jugador entrando en transición -> ",
		destination_region
	)

	_preparar_transicion()

	var error := get_tree().change_scene_to_file(
		destination_scene
	)

	if error != OK:

		_transition_used = false

		push_error(
			"PLONPY: Error cambiando de escena -> "
			+ str(error)
		)


# ============================================================
# DESBLOQUEO
# ============================================================

func _bosque_desbloqueado() -> bool:

	return "M003" in GameManager.completed_missions


# ============================================================
# PREPARAR TRANSICIÓN
# ============================================================

func _preparar_transicion() -> void:

	GameManager.preparar_transicion(
		destination_region,
		destination_scene,
		destination_spawn_position
	)

	print(
		"PLONPY: Región destino -> ",
		GameManager.current_region
	)

	print(
		"PLONPY: Spawn destino -> ",
		GameManager.pending_region_transition_position
	)
