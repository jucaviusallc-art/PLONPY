extends Area3D

## ============================================================
## PLONPY - NÚCLEO COLECCIONABLE 0.2
## Recolección robusta para Núcleos comunes y raros.
## ============================================================

@export var nucleus_id: String = ""
@export var title: String = "Núcleo"
@export var rarity: String = "Común"
@export_multiline var description: String = ""
@export var reward_xp: int = 10
@export var reward_chispa: int = 0
@export var rotation_speed: float = 0.9
@export var bob_height: float = 0.18
@export var bob_speed: float = 2.2
@export var pickup_distance: float = 1.35

var collected := false
var base_y := 0.0
var elapsed := 0.0

var mesh_visual: MeshInstance3D
var material_energy: StandardMaterial3D
var light: OmniLight3D


func _ready() -> void:
	base_y = position.y

	mesh_visual = get_node_or_null("Mesh") as MeshInstance3D

	if nucleus_id.is_empty():
		nucleus_id = name.to_snake_case()

	if title.is_empty():
		title = name.capitalize()

	if GameManager.has_nucleus(nucleus_id):
		queue_free()
		return

	_ensure_collision()
	_create_visual_fx()

	monitoring = true
	monitorable = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	print(
		"PLONPY: Núcleo preparado -> ",
		nucleus_id,
		" | ",
		rarity
	)


func _ensure_collision() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D

	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)

	if collision.shape == null:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.82
		collision.shape = sphere


func _create_visual_fx() -> void:
	if mesh_visual == null:
		return

	material_energy = StandardMaterial3D.new()

	var rare := rarity.to_lower() == "raro"

	material_energy.albedo_color = (
		Color("#B86CFF")
		if rare
		else Color("#5DFFD1")
	)

	material_energy.emission_enabled = true

	material_energy.emission = (
		Color("#8C45FF")
		if rare
		else Color("#20FFAE")
	)

	material_energy.emission_energy_multiplier = (
		3.5
		if rare
		else 2.8
	)

	mesh_visual.material_override = material_energy

	light = OmniLight3D.new()
	light.name = "LuzNucleo"

	light.light_color = (
		Color("#A66CFF")
		if rare
		else Color("#4DFFC2")
	)

	light.light_energy = (
		1.3
		if rare
		else 0.9
	)

	light.omni_range = (
		3.0
		if rare
		else 2.5
	)

	light.shadow_enabled = false

	add_child(light)


func _process(delta: float) -> void:
	if collected:
		return

	elapsed += delta

	rotation.y += rotation_speed * delta
	position.y = base_y + sin(elapsed * bob_speed) * bob_height

	var pulse := (sin(elapsed * 4.0) + 1.0) * 0.5

	if material_energy != null:
		material_energy.emission_energy_multiplier = 2.7 + pulse * 2.0

	if light != null:
		light.light_energy = 0.8 + pulse * 1.0


func _physics_process(_delta: float) -> void:
	if collected:
		return

	var jugador := get_tree().current_scene.get_node_or_null("Jugador")

	if jugador == null:
		return

	if not jugador is CharacterBody3D:
		return

	# Segunda vía de recolección:
	# además de body_entered, usamos distancia para evitar que
	# una diferencia de capas/máscaras de física deje un núcleo
	# imposible de recoger.
	if global_position.distance_to(jugador.global_position) <= pickup_distance:
		_collect(jugador)


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return

	if body == null:
		return

	if body.name != "Jugador":
		return

	_collect(body)


func _collect(_body: Node3D) -> void:
	if collected:
		return

	if GameManager.has_nucleus(nucleus_id):
		return

	collected = true
	monitoring = false

	if not GameManager.register_nucleus(nucleus_id):
		collected = false
		monitoring = true
		return

	print(
		"PLONPY: Núcleo descubierto -> ",
		title,
		" | Rareza: ",
		rarity
	)

	if reward_xp > 0:
		ProgressionManager.add_xp(reward_xp)

	if reward_chispa > 0:
		ProgressionManager.add_chispa(reward_chispa)

	var hud := get_tree().current_scene.get_node_or_null("HUD")

	if hud != null and hud.has_method("show_message"):
		hud.show_message(
			"💠 %s\n%s" % [title, description],
			3.5
		)

	print("PLONPY: Núcleo recogido correctamente -> ", nucleus_id)
	print("PLONPY: El guardado en disco se realizará únicamente con G.")

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"scale",
		scale * 1.8,
		0.20
	)

	if material_energy != null:
		tween.tween_property(
			material_energy,
			"emission_energy_multiplier",
			8.0,
			0.16
		)

	if light != null:
		tween.tween_property(
			light,
			"light_energy",
			5.0,
			0.16
		)

	tween.set_parallel(false)
	tween.tween_interval(0.10)
	tween.tween_callback(queue_free)
