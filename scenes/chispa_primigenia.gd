extends MeshInstance3D

## ============================================================
## PLONPY — CHISPA PRIMIGENIA 0.6
## Detección robusta para completar M002.
## ============================================================

const ID_NUCLEO := "chispa_primigenia"

var altura_inicial := 0.0
var tiempo := 0.0
var posicion_x_inicial := 0.0

var material_energia: StandardMaterial3D
var luz: OmniLight3D
var particulas: GPUParticles3D
var area_deteccion: Area3D
var escala_base := Vector3.ONE
var recogida := false


func _ready() -> void:
	altura_inicial = position.y
	posicion_x_inicial = position.x
	escala_base = scale

	_materializar()
	_crear_luz()
	_crear_particulas()
	_configurar_deteccion()

	if not GameManager.nucleus_collected.is_connected(_on_nucleus_collected):
		GameManager.nucleus_collected.connect(_on_nucleus_collected)

	call_deferred("_comprobar_estado_guardado")

	print("PLONPY: Chispa Primigenia -> VFX 0.6 activo.")


func _materializar() -> void:
	material_energia = StandardMaterial3D.new()
	material_energia.albedo_color = Color("#35F4FF")
	material_energia.emission_enabled = true
	material_energia.emission = Color("#35F4FF")
	material_energia.emission_energy_multiplier = 3.0
	material_override = material_energia


func _crear_luz() -> void:
	luz = OmniLight3D.new()
	luz.name = "LuzChispa"
	luz.light_color = Color("#35F4FF")
	luz.light_energy = 2.2
	luz.omni_range = 4.5
	luz.shadow_enabled = false
	add_child(luz)


func _crear_particulas() -> void:
	particulas = GPUParticles3D.new()
	particulas.name = "ParticulasChispa"
	particulas.amount = 28
	particulas.lifetime = 1.8
	particulas.randomness = 0.65
	particulas.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))

	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proceso.emission_sphere_radius = 0.18
	proceso.direction = Vector3(0, 1, 0)
	proceso.spread = 35.0
	proceso.initial_velocity_min = 0.25
	proceso.initial_velocity_max = 0.65
	proceso.gravity = Vector3(0, -0.12, 0)
	proceso.scale_min = 0.025
	proceso.scale_max = 0.065
	proceso.color = Color(0.45, 0.95, 1.0, 0.78)
	particulas.process_material = proceso

	var esfera := SphereMesh.new()
	esfera.radius = 0.035
	esfera.height = 0.07
	esfera.radial_segments = 6
	esfera.rings = 3

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.45, 0.95, 1.0, 0.85)
	material.emission_enabled = true
	material.emission = Color(0.25, 0.9, 1.0)
	material.emission_energy_multiplier = 3.0
	esfera.material = material

	particulas.draw_pass_1 = esfera
	add_child(particulas)
	particulas.emitting = true


func _configurar_deteccion() -> void:
	area_deteccion = get_node_or_null("Area3D")

	if area_deteccion == null:
		print("PLONPY: ERROR -> Chispa Primigenia no tiene Area3D.")
		return

	area_deteccion.monitoring = true
	area_deteccion.monitorable = true

	if not area_deteccion.body_entered.is_connected(_on_area_body_entered):
		area_deteccion.body_entered.connect(_on_area_body_entered)

	print("PLONPY: Detector de Chispa Primigenia -> ACTIVO.")


func _physics_process(_delta: float) -> void:
	if recogida or GameManager.is_loading_game:
		return

	var jugador := get_tree().current_scene.get_node_or_null("Jugador")

	if jugador == null or not jugador is CharacterBody3D:
		return

	# Detección por distancia además del Area3D.
	if global_position.distance_to(jugador.global_position) <= 1.55:
		_recoger()


func _on_area_body_entered(body: Node3D) -> void:
	if recogida or GameManager.is_loading_game:
		return

	if body == null or body.name != "Jugador":
		return

	_recoger()


func _recoger() -> void:
	if recogida:
		return

	if GameManager.has_nucleus(ID_NUCLEO):
		return

	recogida = true

	print("¡El jugador tocó la Chispa Primigenia!")

	GameManager.register_nucleus(ID_NUCLEO)

	print("PLONPY: Chispa Primigenia registrada en memoria.")
	print("PLONPY: El guardado en disco se realizará únicamente con G.")


func _comprobar_estado_guardado() -> void:
	if GameManager.has_nucleus(ID_NUCLEO):
		print("PLONPY: Chispa Primigenia ya obtenida. No reaparecerá.")
		queue_free()


func _process(delta: float) -> void:
	if recogida:
		return

	tiempo += delta

	position.y = altura_inicial + sin(tiempo * 2.0) * 0.25
	position.x = posicion_x_inicial + sin(tiempo * 1.2) * 0.50
	rotation.y += delta * 3.0

	var pulso := (sin(tiempo * 4.0) + 1.0) * 0.5
	scale = escala_base * (1.0 + pulso * 0.10)

	if material_energia != null:
		material_energia.emission_energy_multiplier = 2.8 + pulso * 2.0

	if luz != null:
		luz.light_energy = 1.7 + pulso * 1.5
		luz.omni_range = 4.0 + pulso


func _on_nucleus_collected(nucleus_id: String) -> void:
	if nucleus_id != ID_NUCLEO:
		return

	if not recogida:
		recogida = true

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "scale", escala_base * 1.75, 0.22)

	if material_energia != null:
		tween.tween_property(
			material_energia,
			"emission_energy_multiplier",
			8.0,
			0.18
		)

	if luz != null:
		tween.tween_property(luz, "light_energy", 6.0, 0.18)

	tween.set_parallel(false)
	tween.tween_interval(0.12)
	tween.tween_callback(queue_free)
