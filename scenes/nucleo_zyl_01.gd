extends MeshInstance3D

## ============================================================
## PLONPY - NÚCLEO ZYL
## VFX 4.2 + Registro de colección
## SIN GUARDADO AUTOMÁTICO
##
## El estado se registra en GameManager.
## La escritura en disco ocurre únicamente mediante G.
## ============================================================

const ID_NUCLEO: String = "nucleo_zyl_01"

var altura_inicial: float
var tiempo: float = 0.0
var posicion_x_inicial: float

var material_energia: StandardMaterial3D
var luz: OmniLight3D
var particulas: GPUParticles3D

var escala_base := Vector3.ONE
var recogido := false

@onready var area_3d: Area3D = $Area3D


func _ready() -> void:
	altura_inicial = position.y
	posicion_x_inicial = position.x
	escala_base = scale

	_materializar()
	_crear_luz()
	_crear_particulas()

	# ========================================================
	# Si el núcleo ya estaba guardado, no debe reaparecer.
	# ========================================================
	if GameManager.has_nucleus(ID_NUCLEO):
		print("PLONPY: Núcleo ZYL ya obtenido. No reaparecerá.")
		queue_free()
		return

	if not area_3d.body_entered.is_connected(_on_area_3d_body_entered):
		area_3d.body_entered.connect(_on_area_3d_body_entered)

	print("PLONPY: Núcleo ZYL -> VFX 4.2 activo.")


func _materializar() -> void:
	material_energia = StandardMaterial3D.new()

	material_energia.albedo_color = Color("#A86BFF")

	material_energia.emission_enabled = true
	material_energia.emission = Color("#A86BFF")
	material_energia.emission_energy_multiplier = 3.5

	material_override = material_energia


func _crear_luz() -> void:
	luz = OmniLight3D.new()

	luz.name = "LuzZYL"
	luz.light_color = Color("#B06CFF")
	luz.light_energy = 1.8
	luz.omni_range = 3.8
	luz.shadow_enabled = false

	add_child(luz)


func _crear_particulas() -> void:
	particulas = GPUParticles3D.new()

	particulas.name = "ParticulasZYL"
	particulas.amount = 22
	particulas.lifetime = 1.6
	particulas.randomness = 0.7

	particulas.visibility_aabb = AABB(
		Vector3(-2, -2, -2),
		Vector3(4, 4, 4)
	)

	var proceso := ParticleProcessMaterial.new()

	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proceso.emission_sphere_radius = 0.16

	proceso.direction = Vector3(0, 1, 0)
	proceso.spread = 40.0

	proceso.initial_velocity_min = 0.18
	proceso.initial_velocity_max = 0.55

	proceso.gravity = Vector3(0, -0.10, 0)

	proceso.scale_min = 0.02
	proceso.scale_max = 0.055

	proceso.color = Color(0.68, 0.42, 1.0, 0.8)

	particulas.process_material = proceso

	var esfera := SphereMesh.new()

	esfera.radius = 0.03
	esfera.height = 0.06
	esfera.radial_segments = 6
	esfera.rings = 3

	var material := StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	material.albedo_color = Color(
		0.68,
		0.42,
		1.0,
		0.85
	)

	material.emission_enabled = true
	material.emission = Color(0.55, 0.28, 1.0)
	material.emission_energy_multiplier = 3.0

	esfera.material = material

	particulas.draw_pass_1 = esfera

	add_child(particulas)

	particulas.emitting = true


func _process(delta: float) -> void:
	if recogido:
		return

	tiempo += delta

	position.y = altura_inicial + sin(tiempo * 2.0) * 0.25
	position.x = posicion_x_inicial + sin(tiempo * 1.2) * 0.20

	rotation.y += delta * 1.5

	var pulso := (sin(tiempo * 4.8 + 0.7) + 1.0) * 0.5
	var factor := 1.0 + pulso * 0.08

	scale = escala_base * factor

	if material_energia != null:
		material_energia.emission_energy_multiplier = 3.0 + pulso * 2.2

	if luz != null:
		luz.light_energy = 1.5 + pulso * 1.2


func _on_area_3d_body_entered(body: Node3D) -> void:

	# ========================================================
	# PROTECCIÓN DE CARGA
	# Nunca recoger un núcleo mientras se reconstruye
	# una partida.
	# ========================================================
	if GameManager.is_loading_game:
		return

	if recogido:
		return

	if body == null:
		return

	if body.name != "Jugador":
		return

	if GameManager.has_nucleus(ID_NUCLEO):
		return

	recogido = true

	print("¡Núcleo ZYL descubierto!")

	if GameManager.register_nucleus(ID_NUCLEO):

		var escena := get_tree().current_scene

		if escena != null:
			var hud := escena.get_node_or_null("HUD")

			if hud != null and hud.has_method("show_message"):
				hud.show_message(
					" Núcleo ZYL descubierto",
					3.0
				)

		# ====================================================
		# IMPORTANTE:
		# NO GUARDAR AUTOMÁTICAMENTE.
		#
		# El núcleo queda registrado en GameManager.
		# El usuario decide cuándo escribirlo al disco
		# mediante la tecla G.
		# ====================================================

		print("PLONPY: Núcleo ZYL registrado en memoria.")
		print("PLONPY: El guardado en disco se realizará únicamente con G.")

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		escala_base * 1.65,
		0.20
	)

	tween.tween_property(
		material_energia,
		"emission_energy_multiplier",
		8.0,
		0.16
	)

	if luz != null:
		tween.tween_property(
			luz,
			"light_energy",
			5.0,
			0.16
		)

	tween.set_parallel(false)

	tween.tween_interval(0.10)

	tween.tween_callback(queue_free)
