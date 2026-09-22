extends CharacterBody3D
## PLONPY - JUGADOR 0.2
## Movimiento, gravedad, límites de seguridad y persistencia de posición.

const SPEED: float = 5.0
const GRAVITY: float = 18.0
const FALL_LIMIT: float = -8.0
const WORLD_X_LIMIT: float = 7.2
const WORLD_Z_LIMIT: float = 6.2
const DISTANCIA_REACCION: float = 5.0

@onready var ojo_izquierdo: Node3D = $MeshInstance3D2
@onready var ojo_derecho: Node3D = $MeshInstance3D3
@onready var chispa_primigenia: Node3D = get_parent().get_node_or_null("ChispaPrimigenia")
@onready var mensaje_nucleo: Label = get_parent().get_node_or_null("MensajeNucleo") as Label

var posicion_ojo_izquierdo: Vector3
var posicion_ojo_derecho: Vector3
var mirada_actual: float = 0.0
var mirada_objetivo: float = 0.0
var tiempo_mirada: float = 0.0
var proxima_mirada: float = 1.5

func _ready() -> void:
    posicion_ojo_izquierdo = ojo_izquierdo.position
    posicion_ojo_derecho = ojo_derecho.position

    if mensaje_nucleo != null:
        mensaje_nucleo.visible = false

    GameManager.set_current_region("costa_de_chispa")

    if not get_tree().current_scene.scene_file_path.is_empty():
        GameManager.current_scene = get_tree().current_scene.scene_file_path

    if GameManager.has_saved_position and not GameManager.is_loading_game:
        global_position = GameManager.player_spawn_position

    print("PLONPY: Jugador iniciado en Costa de Chispa.")

func _physics_process(delta: float) -> void:
    var direccion := Vector3.ZERO

    if Input.is_action_pressed("mover_arriba"):
        direccion.z -= 1.0
    if Input.is_action_pressed("mover_abajo"):
        direccion.z += 1.0
    if Input.is_action_pressed("mover_izquierda"):
        direccion.x -= 1.0
    if Input.is_action_pressed("mover_derecha"):
        direccion.x += 1.0

    if direccion.length() > 0.0:
        direccion = direccion.normalized()

    velocity.x = direccion.x * SPEED
    velocity.z = direccion.z * SPEED

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()

    # Cinturón de seguridad adicional: la colisión es la protección principal.
    global_position.x = clamp(global_position.x, -WORLD_X_LIMIT, WORLD_X_LIMIT)
    global_position.z = clamp(global_position.z, -WORLD_Z_LIMIT, WORLD_Z_LIMIT)

    if global_position.y < FALL_LIMIT:
        global_position = Vector3(0.0, 1.25, 0.0)
        velocity = Vector3.ZERO
        print("PLONPY: Recuperación de seguridad: jugador fuera del mundo.")

    GameManager.set_player_position(global_position)

    _actualizar_mirada(delta)

func _actualizar_mirada(delta: float) -> void:
    tiempo_mirada += delta

    if tiempo_mirada >= proxima_mirada:
        tiempo_mirada = 0.0
        mirada_objetivo = randf_range(-0.08, 0.08)
        proxima_mirada = randf_range(1.0, 3.0)

    mirada_actual = lerp(mirada_actual, mirada_objetivo, delta * 3.0)

    var reaccion_nucleo := 0.0

    if is_instance_valid(chispa_primigenia):
        var distancia := global_position.distance_to(chispa_primigenia.global_position)

        if distancia <= DISTANCIA_REACCION:
            var diferencia_x := chispa_primigenia.global_position.x - global_position.x
            reaccion_nucleo = clamp(diferencia_x * 0.06, -0.15, 0.15)

    var movimiento_final := mirada_actual + reaccion_nucleo

    ojo_izquierdo.position.x = posicion_ojo_izquierdo.x + movimiento_final
    ojo_derecho.position.x = posicion_ojo_derecho.x + movimiento_final

func _on_area_3d_body_entered(body: Node3D) -> void:
    if body != self or GameManager.has_nucleus("chispa_primigenia"):
        return

    print("¡El jugador tocó la Chispa Primigenia!")

    var escena_padre := get_parent()

    if escena_padre.has_method("registrar_chispa_primigenia"):
        escena_padre.registrar_chispa_primigenia()

    GameManager.register_nucleus("chispa_primigenia")

    if mensaje_nucleo != null:
        mensaje_nucleo.visible = true

    if is_instance_valid(chispa_primigenia):
        chispa_primigenia.queue_free()
        chispa_primigenia = null

    if mensaje_nucleo != null:
        await get_tree().create_timer(3.0).timeout
        if is_instance_valid(mensaje_nucleo):
            mensaje_nucleo.visible = false
