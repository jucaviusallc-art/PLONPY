extends Area3D

## ============================================================
## PLONPY - DISCOVERY 1.5
## Sistema de descubrimientos
##
## SIN GUARDADO AUTOMÁTICO
##
## Los descubrimientos se registran en ExplorationManager.
## El progreso de M003 se comunica a MissionManager.
## La escritura en disco ocurre únicamente mediante G.
## ============================================================


@export var discovery_id: String = ""
@export var title: String = ""
@export_multiline var message: String = ""

@export var rotation_speed: float = 0.8
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.0
@export var collision_radius: float = 0.75


var collected: bool = false
var base_y: float = 0.0
var elapsed: float = 0.0


func _exploration_manager() -> Node:
	return get_node_or_null("/root/ExplorationManager")


func _mission_manager() -> Node:
	return get_node_or_null("/root/MissionManager")


func _ready() -> void:

	base_y = position.y

	# ========================================================
	# AUTORREPARACIÓN DE METADATOS
	# ========================================================

	if discovery_id.is_empty():
		discovery_id = name.to_snake_case()

	if title.is_empty():
		title = name.capitalize()

	if message.is_empty():
		message = title + " descubierto."

	var exploration := _exploration_manager()

	if exploration != null:

		if exploration.has_method("has_discovery"):

			if exploration.has_discovery(discovery_id):

				print(
					"PLONPY: Descubrimiento ya obtenido -> ",
					discovery_id
				)

				queue_free()
				return

	_ensure_collision()

	monitoring = true
	monitorable = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	print(
		"PLONPY: Discovery preparado -> ",
		discovery_id
	)


func _ensure_collision() -> void:

	var collision := get_node_or_null(
		"CollisionShape3D"
	) as CollisionShape3D

	if collision == null:

		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"

		var sphere := SphereShape3D.new()
		sphere.radius = collision_radius

		collision.shape = sphere

		add_child(collision)

		print(
			"PLONPY: Colisión automática creada -> ",
			discovery_id
		)

	else:

		if collision.shape == null:

			var sphere := SphereShape3D.new()
			sphere.radius = collision_radius

			collision.shape = sphere


func _process(delta: float) -> void:

	if collected:
		return

	elapsed += delta

	rotation.y += rotation_speed * delta

	position.y = (
		base_y
		+ sin(elapsed * bob_speed) * bob_height
	)


func _on_body_entered(body: Node3D) -> void:

	# ========================================================
	# PROTECCIÓN DE CARGA
	# ========================================================

	if GameManager.is_loading_game:
		return

	if collected:
		return

	if body == null:
		return

	if body.name != "Jugador":
		return

	var exploration := _exploration_manager()

	if exploration == null:
		return

	if not exploration.has_method("register_discovery"):
		return

	collected = true

	var registrado: bool = exploration.register_discovery(
		discovery_id,
		title
	)

	if not registrado:

		print(
			"PLONPY: Discovery rechazado -> ",
			discovery_id
		)

		collected = false
		return

	print(
		"PLONPY: ",
		name,
		" descubierto."
	)

	# ========================================================
	# NOTIFICACIÓN
	# ========================================================

	var ui := get_node_or_null(
		"/root/UIManager"
	)

	if ui != null and ui.has_method("show_notification"):

		ui.show_notification(
			"DESCUBRIMIENTO",
			title + " — " + message
		)

	else:

		var scene := get_tree().current_scene

		if scene != null:

			var hud := scene.get_node_or_null(
				"HUD"
			)

			if hud != null and hud.has_method(
				"show_message"
			):

				hud.show_message(
					message,
					3.0
				)

	# ========================================================
	# MISIÓN M003
	# ========================================================
	# El descubrimiento ya fue registrado correctamente.
	# Ahora comunicamos el avance al MissionManager.
	#
	# IMPORTANTE:
	# Esto NO guarda en disco.
	# Solo modifica el estado en memoria.
	# ========================================================

	var mission := _mission_manager()

	if mission != null and mission.has_method(
		"register_discovery_progress"
	):

		mission.register_discovery_progress(
			discovery_id
		)

		print(
			"PLONPY: Progreso de misión actualizado -> ",
			discovery_id
		)

	# ========================================================
	# SIN GUARDADO AUTOMÁTICO
	# ========================================================

	print(
		"PLONPY: Descubrimiento registrado en memoria -> ",
		discovery_id
	)

	print(
		"PLONPY: El guardado en disco se realizará únicamente con G."
	)

	queue_free()
