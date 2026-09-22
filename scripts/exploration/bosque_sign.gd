extends Area3D

## PLONPY - SEÑAL DEL BOSQUE 0.1
## Descubrimientos ambientales independientes de las misiones formales.

@export var discovery_id: String = ""
@export var title: String = "Señal del bosque"
@export_multiline var message: String = "El bosque guarda un recuerdo."

var base_y := 0.0
var elapsed := 0.0
var collected := false

func _ready() -> void:
	base_y = position.y
	if discovery_id.is_empty():
		discovery_id = name.to_snake_case()
	if ExplorationManager.has_discovery(discovery_id):
		queue_free()
		return
	monitoring = true
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if collected:
		return
	elapsed += delta
	rotation.y += delta * 0.6
	position.y = base_y + sin(elapsed * 2.0) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if collected or body == null or body.name != "Jugador":
		return
	if not ExplorationManager.register_discovery(discovery_id, title):
		return
	collected = true
	print("PLONPY: Señal del bosque -> ", title)
	var hud := get_tree().current_scene.get_node_or_null("HUD")
	if hud != null and hud.has_method("show_message"):
		hud.show_message("🌿 %s\n%s" % [title, message], 3.0)
	SaveManager.save_game()
	queue_free()
