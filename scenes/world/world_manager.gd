extends Node

## PLONPY - WORLD MANAGER 0.4
## Blindaje absoluto de colisión de suelo y ordenamiento de coleccionables.

const REGION_SCENE := "res://scenes/costa_de_chispa.tscn"

func _ready() -> void:
	call_deferred("_build_current_scene")

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
		print("PLONPY: WorldManager -> Costa de Chispa sincronizada con suelo sólido.")

func _ensure_floor_collision(scene: Node3D) -> void:
	var floor := scene.get_node_or_null("SueloCosta") as Node3D
	if floor == null:
		return
	
	if floor is CSGBox3D:
		floor.use_collision = true

	if floor.get_node_or_null("SueloFisicoSeguro") == null:
		var static_body = StaticBody3D.new()
		static_body.name = "SueloFisicoSeguro"
		floor.add_child(static_body)

		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
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
