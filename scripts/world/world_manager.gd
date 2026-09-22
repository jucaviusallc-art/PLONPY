extends Node

## PLONPY - WORLD MANAGER 0.5
## Blindaje de suelo + organización de coleccionables + transición de regiones.

const REGION_SCENE := "res://scenes/costa_de_chispa.tscn"
const BOSQUE_SCENE := "res://scenes/regions/bosque_de_vetas.tscn"
const GATEWAY_NAME := "PortalBosqueDeVetas"

var gateway: Area3D
var transition_busy: bool = false

func _ready() -> void:
	call_deferred("_build_current_scene")

	var mission := get_node_or_null("/root/MissionManager")
	if mission != null and mission.has_signal("mission_completed"):
		if not mission.mission_completed.is_connected(_on_mission_completed):
			mission.mission_completed.connect(_on_mission_completed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED or what == NOTIFICATION_ENTER_TREE:
		call_deferred("_build_current_scene")

func _build_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	if scene.scene_file_path == REGION_SCENE:
		_ensure_floor_collision(scene)
		_organize_collectibles(scene)
		_sync_bosque_gateway(scene)
		print("PLONPY: WorldManager -> Costa de Chispa sincronizada con suelo sólido.")

func _on_mission_completed(mission_id: String) -> void:
	if mission_id == "M003":
		call_deferred("_build_current_scene")

func _sync_bosque_gateway(scene: Node3D) -> void:
	var game := get_node_or_null("/root/GameManager")
	if game == null:
		return

	var unlocked: bool = "M003" in game.completed_missions
	var existing := scene.get_node_or_null(GATEWAY_NAME) as Area3D

	if unlocked and existing == null:
		_create_bosque_gateway(scene)
	elif not unlocked and existing != null:
		existing.queue_free()
		gateway = null
	elif existing != null:
		gateway = existing

func _create_bosque_gateway(scene: Node3D) -> void:
	gateway = Area3D.new()
	gateway.name = GATEWAY_NAME
	gateway.position = Vector3(7.0, 1.1, 0.0)
	gateway.collision_layer = 2
	gateway.collision_mask = 1
	gateway.monitoring = true
	gateway.monitorable = true
	scene.add_child(gateway)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	collision.shape = shape
	gateway.add_child(collision)

	var ring := MeshInstance3D.new()
	ring.name = "Anillo"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.82
	torus.rings = 24
	torus.ring_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#62FFB0")
	material.emission_enabled = true
	material.emission = Color("#24FF9A")
	material.emission_energy_multiplier = 4.0
	torus.material = material
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	gateway.add_child(ring)

	var core := MeshInstance3D.new()
	core.name = "NucleoPortal"
	var sphere := SphereMesh.new()
	sphere.radius = 0.52
	sphere.height = 1.04
	var core_mat := StandardMaterial3D.new()
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.albedo_color = Color(0.15, 1.0, 0.65, 0.32)
	core_mat.emission_enabled = true
	core_mat.emission = Color("#27FF9E")
	core_mat.emission_energy_multiplier = 2.5
	sphere.material = core_mat
	core.mesh = sphere
	gateway.add_child(core)

	var label := Label3D.new()
	label.name = "Etiqueta"
	label.text = "BOSQUE DE VETAS\nLa señal te espera"
	label.position = Vector3(0, 1.35, 0)
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color("#D7FFE9")
	gateway.add_child(label)

	gateway.body_entered.connect(_on_gateway_body_entered)
	print("PLONPY: Portal -> Bosque de Vetas desbloqueado.")

func _on_gateway_body_entered(body: Node3D) -> void:
	if transition_busy or body == null or body.name != "Jugador":
		return

	var game := get_node_or_null("/root/GameManager")
	if game == null or "M003" not in game.completed_missions:
		return

	transition_busy = true
	game.is_loading_game = true
	game.current_region = "bosque_de_vetas"
	print("PLONPY: Transición -> Bosque de Vetas.")

	var error := get_tree().change_scene_to_file(BOSQUE_SCENE)
	if error != OK:
		game.is_loading_game = false
		transition_busy = false
		push_error("PLONPY: No se pudo abrir Bosque de Vetas. Error %d" % error)

func _ensure_floor_collision(scene: Node3D) -> void:
	var floor := scene.get_node_or_null("SueloCosta") as Node3D
	if floor == null:
		return

	if floor is CSGBox3D:
		floor.use_collision = true

	if floor.get_node_or_null("SueloFisicoSeguro") == null:
		var static_body := StaticBody3D.new()
		static_body.name = "SueloFisicoSeguro"
		floor.add_child(static_body)

		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(16.0, 0.5, 14.0)
		collision.shape = shape
		static_body.add_child(collision)
		print("PLONPY: SueloFisicoSeguro -> Acoplado correctamente.")

func _organize_collectibles(scene: Node3D) -> void:
	_set_position_if_exists(scene, "ChispaPrimigenia", Vector3(-4.8, 0.8, -1.8))
	_set_position_if_exists(scene, "NucleoZyl01", Vector3(2.8, 0.8, 1.8))
	_set_position_if_exists(scene, "EcoDeCosta", Vector3(-5.2, 0.8, 4.0))
	_set_position_if_exists(scene, "GotaDeLuz", Vector3(4.8, 0.8, -3.8))
	_set_position_if_exists(scene, "BurbujaDeEnergia", Vector3(5.2, 0.8, 4.0))

func _set_position_if_exists(scene: Node3D, node_name: String, position: Vector3) -> void:
	var node := scene.get_node_or_null(node_name)
	if node is Node3D:
		node.position = position
