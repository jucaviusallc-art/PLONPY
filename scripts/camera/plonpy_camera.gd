extends Camera3D
## PLONPY - Cámara reactiva 4.1
## Alternativa si se desea separar la cámara del FX de la región.

@export var fov_normal := 68.0
@export var fov_movimiento := 70.0
@export var suavizado := 0.08
@export var intensidad_bob := 0.018
@export var frecuencia_bob := 8.0

var _base_position := Vector3.ZERO
var _tiempo := 0.0
var _player: CharacterBody3D

func _ready() -> void:
	_base_position = position
	_player = get_parent() as CharacterBody3D
	current = true
	fov = fov_normal

func _process(delta: float) -> void:
	_tiempo += delta
	if not is_instance_valid(_player):
		return

	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var moving := speed > 0.1

	var target_fov := fov_normal
	var bob := 0.0
	if moving:
		target_fov = fov_movimiento
		bob = sin(_tiempo * frecuencia_bob) * intensidad_bob

	fov = lerp(fov, target_fov, suavizado)
	position.y = lerp(position.y, _base_position.y + bob, 0.12)
