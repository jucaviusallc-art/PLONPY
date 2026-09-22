extends Node3D
## PLONPY - FASE 4.1
## Atmósfera + VFX + cámara + feedback para Costa de Chispa.
##
## Este script está diseñado para añadirse al nodo raíz CostaDeChispa.
## No requiere texturas, modelos ni plugins externos.

const REGION_ID := "costa_de_chispa"

@export var activar_particulas := true
@export var activar_fog := true
@export var activar_camara := true
@export var activar_agua := true

var _player: CharacterBody3D
var _camera: Camera3D
var _water: Node3D
var _environment: WorldEnvironment
var _ambient_particles: GPUParticles3D
var _time := 0.0
var _camera_base_position := Vector3.ZERO
var _feedback_tween: Tween


func _ready() -> void:
	print("PLONPY: FXManager 4.1 iniciado.")
	GameManager.set_current_region(REGION_ID)

	_find_world_nodes()
	_setup_environment()
	_setup_ambient_particles()
	_setup_water_feedback()
	_setup_camera()
	_connect_game_feedback()

	print("PLONPY: Atmósfera Costa de Chispa preparada.")
	print("PLONPY: VFX ambientales -> ", "ACTIVOS" if activar_particulas else "DESACTIVADOS")
	print("PLONPY: Cámara reactiva -> ", "ACTIVA" if activar_camara else "DESACTIVADA")


func _process(delta: float) -> void:
	_time += delta

	if activar_agua and is_instance_valid(_water):
		_animate_water(delta)

	if activar_camara and is_instance_valid(_camera) and is_instance_valid(_player):
		_animate_camera(delta)


func _find_world_nodes() -> void:
	# El FX vive como hijo de CostaDeChispa para no reemplazar
	# el script de lógica de la región.
	var mundo: Node = get_parent()
	_player = mundo.get_node_or_null("Jugador") as CharacterBody3D
	_camera = mundo.get_node_or_null("Jugador/Camera3D") as Camera3D

	if _camera == null:
		_camera = get_viewport().get_camera_3d()

	_water = mundo.get_node_or_null("AguaCosta")

	_environment = mundo.get_node_or_null("WorldEnvironment") as WorldEnvironment

	if _camera != null:
		_camera_base_position = _camera.position


func _setup_environment() -> void:
	if not activar_fog:
		return

	if _environment == null:
		_environment = WorldEnvironment.new()
		_environment.name = "WorldEnvironmentFX"
		add_child(_environment)

	if _environment.environment == null:
		_environment.environment = Environment.new()

	var env := _environment.environment
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.12

	# Niebla suave, suficiente para profundidad sin ocultar el escenario.
	env.fog_enabled = true
	env.fog_light_color = Color(0.30, 0.55, 0.60, 1.0)
	env.fog_light_energy = 0.45
	env.fog_density = 0.008
	env.fog_height = 1.5
	env.fog_height_density = 0.08

	# Ajustes que ayudan al aspecto luminoso de los objetos.
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY


func _setup_ambient_particles() -> void:
	if not activar_particulas or _ambient_particles != null:
		return

	_ambient_particles = GPUParticles3D.new()
	_ambient_particles.name = "ParticulasAmbientales"
	_ambient_particles.amount = 70
	_ambient_particles.lifetime = 7.0
	_ambient_particles.randomness = 0.75
	_ambient_particles.visibility_aabb = AABB(Vector3(-8, -1, -7), Vector3(16, 8, 14))

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(7.0, 3.0, 6.0)
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 180.0
	process_material.initial_velocity_min = 0.08
	process_material.initial_velocity_max = 0.22
	process_material.gravity = Vector3(0.0, 0.02, 0.0)
	process_material.scale_min = 0.015
	process_material.scale_max = 0.035
	process_material.color = Color(0.55, 0.95, 1.0, 0.65)

	_ambient_particles.process_material = process_material

	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	mesh.radial_segments = 6
	mesh.rings = 3

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.95, 1.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.35, 0.9, 1.0)
	material.emission_energy_multiplier = 2.5
	mesh.material = material

	_ambient_particles.draw_pass_1 = mesh
	_ambient_particles.position = Vector3(0.0, 1.0, 0.0)
	add_child(_ambient_particles)
	_ambient_particles.emitting = true


func _setup_water_feedback() -> void:
	if not activar_agua or _water == null:
		return

	# CSGBox3D admite material_override. No reemplazamos el objeto ni su colisión.
	var csg := _water as CSGBox3D
	if csg == null:
		return

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.04, 0.35, 0.45, 0.68)
	material.metallic = 0.05
	material.roughness = 0.18
	material.emission_enabled = true
	material.emission = Color(0.02, 0.18, 0.24)
	material.emission_energy_multiplier = 0.55
	csg.material_override = material


func _animate_water(_delta: float) -> void:
	var csg := _water as CSGBox3D
	if csg == null:
		return

	var pulse := (sin(_time * 1.4) + 1.0) * 0.5
	var mat := csg.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = 0.35 + pulse * 0.35


func _setup_camera() -> void:
	if not activar_camara or _camera == null:
		return

	_camera.current = true
	_camera.fov = 68.0


func _animate_camera(_delta: float) -> void:
	if _camera == null or _player == null:
		return

	var horizontal_speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var moving := horizontal_speed > 0.1

	var target_fov := 68.0
	if moving:
		target_fov = 70.0 + min(horizontal_speed * 0.25, 2.0)

	_camera.fov = lerp(_camera.fov, target_fov, 0.08)

	var bob := 0.0
	if moving:
		bob = sin(_time * 8.0) * 0.018

	var target_y := _camera_base_position.y + bob
	_camera.position.y = lerp(_camera.position.y, target_y, 0.12)


func _connect_game_feedback() -> void:
	if GameManager.has_signal("nucleus_collected"):
		if not GameManager.nucleus_collected.is_connected(_on_nucleus_collected):
			GameManager.nucleus_collected.connect(_on_nucleus_collected)

	# Estos nombres permiten convivir con el sistema de descubrimientos actual
	# sin obligar a cambiarlo.
	if has_node("/root/ExplorationManager"):
		var exploration = get_node("/root/ExplorationManager")
		if exploration.has_signal("discovery_registered"):
			if not exploration.discovery_registered.is_connected(_on_discovery_registered):
				exploration.discovery_registered.connect(_on_discovery_registered)


func _on_nucleus_collected(nucleus_id: String) -> void:
	_flash_world()
	print("PLONPY: Feedback VFX -> núcleo ", nucleus_id)


func _on_discovery_registered(discovery_id: String) -> void:
	_flash_world()
	print("PLONPY: Feedback VFX -> descubrimiento ", discovery_id)


func _flash_world() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	# Reacción discreta de cámara: no altera la posición guardada del jugador.
	if _camera != null:
		var original_fov := _camera.fov
		_feedback_tween = create_tween()
		_feedback_tween.tween_property(_camera, "fov", original_fov + 3.0, 0.10)
		_feedback_tween.tween_property(_camera, "fov", original_fov, 0.30)
