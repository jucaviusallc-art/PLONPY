extends CharacterBody3D

# ============================================================
# PLONPY - JUGADOR
# Movimiento + gravedad + protección contra el vacío
# ============================================================

const GRAVITY: float = 9.8
const SPEED: float = 5.0

# ------------------------------------------------------------
# PROTECCIÓN CONTRA EL VACÍO
# ------------------------------------------------------------

# Altura mínima de seguridad.
const VOID_Y_LIMIT: float = -5.0

# Altura desde donde comienza el raycast.
const GROUND_CHECK_HEIGHT: float = 2.5

# Profundidad máxima del raycast.
const GROUND_CHECK_DEPTH: float = 12.0

# Última posición conocida donde el jugador estaba sobre suelo.
var last_safe_position: Vector3 = Vector3.ZERO

# Indica si ya tenemos una posición segura válida.
var has_safe_position: bool = false


func _ready() -> void:
	print("PLONPY: Jugador iniciado con protección real contra el vacío.")

	# La posición inicial se considera segura.
	last_safe_position = global_position
	has_safe_position = true


func _physics_process(delta: float) -> void:

	# --------------------------------------------------------
	# NO MOVER DURANTE LA CARGA
	# --------------------------------------------------------

	if GameManager.is_loading_game:
		return


	# --------------------------------------------------------
	# MOVIMIENTO WASD + FLECHAS
	# --------------------------------------------------------

	var input_x: float = 0.0
	var input_z: float = 0.0

	# A / Flecha izquierda
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0

	# D / Flecha derecha
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0

	# W / Flecha arriba
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_z -= 1.0

	# S / Flecha abajo
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_z += 1.0


	var direction: Vector3 = Vector3(
		input_x,
		0.0,
		input_z
	)

	# Evitar que el movimiento diagonal sea más rápido.
	if direction.length() > 1.0:
		direction = direction.normalized()


	# --------------------------------------------------------
	# VELOCIDAD HORIZONTAL
	# --------------------------------------------------------

	var desired_velocity: Vector3 = Vector3(
		direction.x * SPEED,
		velocity.y,
		direction.z * SPEED
	)


	# --------------------------------------------------------
	# PROTECCIÓN DEL BORDE
	# --------------------------------------------------------

	var horizontal_velocity: Vector3 = Vector3(
		desired_velocity.x,
		0.0,
		desired_velocity.z
	)

	var movimiento_permitido: bool = true


	if horizontal_velocity.length() > 0.001:

		var distancia_movimiento: float = (
			horizontal_velocity.length() * delta
		)

		var posicion_destino: Vector3 = global_position + (
			horizontal_velocity.normalized()
			* distancia_movimiento
		)

		# Si no hay suelo delante, bloqueamos el movimiento.
		if not _hay_suelo_en(posicion_destino):
			movimiento_permitido = false


	# --------------------------------------------------------
	# APLICAR MOVIMIENTO HORIZONTAL
	# --------------------------------------------------------

	if movimiento_permitido:

		velocity.x = desired_velocity.x
		velocity.z = desired_velocity.z

	else:

		# No permitimos entrar al vacío.
		velocity.x = 0.0
		velocity.z = 0.0


	# --------------------------------------------------------
	# GRAVEDAD
	# --------------------------------------------------------

	if not is_on_floor():

		velocity.y -= GRAVITY * delta

	else:

		# Evitar acumulación de velocidad vertical.
		if velocity.y < 0.0:
			velocity.y = 0.0

		# ----------------------------------------------------
		# REGISTRAR POSICIÓN SEGURA
		# ----------------------------------------------------

		last_safe_position = global_position
		has_safe_position = true


	# --------------------------------------------------------
	# MOVIMIENTO FÍSICO
	# --------------------------------------------------------

	move_and_slide()


	# --------------------------------------------------------
	# PROTECCIÓN DE EMERGENCIA
	# --------------------------------------------------------

	if global_position.y < VOID_Y_LIMIT:

		_respawn_en_posicion_segura()
		return


	# --------------------------------------------------------
	# ACTUALIZAR POSICIÓN SEGURA
	# --------------------------------------------------------

	if is_on_floor():

		last_safe_position = global_position
		has_safe_position = true


	# --------------------------------------------------------
	# PROGRESO DE MISIÓN
	# --------------------------------------------------------

	# M001 necesita detectar que el jugador comenzó a explorar.

	if movimiento_permitido and direction.length() > 0.0:

		var mission_manager: Node = (
			get_node_or_null("/root/MissionManager")
		)

		if mission_manager != null:

			if mission_manager.has_method("notify_player_moved"):

				mission_manager.notify_player_moved()


# ============================================================
# COMPROBAR SI EXISTE SUELO EN UNA POSICIÓN
# ============================================================

func _hay_suelo_en(posicion: Vector3) -> bool:

	var mundo: World3D = get_world_3d()

	if mundo == null:
		return true


	var espacio: PhysicsDirectSpaceState3D = (
		mundo.direct_space_state
	)

	if espacio == null:
		return true


	# --------------------------------------------------------
	# RAYO HACIA ABAJO
	# --------------------------------------------------------

	var origen: Vector3 = Vector3(
		posicion.x,
		posicion.y + GROUND_CHECK_HEIGHT,
		posicion.z
	)

	var destino: Vector3 = Vector3(
		posicion.x,
		posicion.y - GROUND_CHECK_DEPTH,
		posicion.z
	)


	# --------------------------------------------------------
	# CONFIGURACIÓN DEL RAYCAST
	# --------------------------------------------------------

	var parametros: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			origen,
			destino
		)
	)

	parametros.exclude = [self]
	parametros.collide_with_bodies = true
	parametros.collide_with_areas = false


	# --------------------------------------------------------
	# REALIZAR RAYCAST
	# --------------------------------------------------------

	var resultado: Dictionary = (
		espacio.intersect_ray(parametros)
	)


	# --------------------------------------------------------
	# COMPROBAR SI ENCONTRÓ SUELO
	# --------------------------------------------------------

	if resultado.is_empty():
		return false


	# --------------------------------------------------------
	# POSICIÓN DE COLISIÓN
	# --------------------------------------------------------

	var punto_colision: Vector3 = resultado["position"]


	# --------------------------------------------------------
	# COMPROBAR DISTANCIA AL SUELO
	# --------------------------------------------------------

	if abs(
		posicion.y - punto_colision.y
	) <= GROUND_CHECK_DEPTH:

		return true


	return false


# ============================================================
# DEVOLVER AL JUGADOR A LA ÚLTIMA POSICIÓN SEGURA
# ============================================================

func _respawn_en_posicion_segura() -> void:

	if not has_safe_position:

		# Seguridad absoluta.
		last_safe_position = Vector3(
			0.0,
			1.0,
			0.0
		)

		has_safe_position = true


	global_position = last_safe_position

	velocity = Vector3.ZERO

	print(
		"PLONPY: Protección de vacío activada -> jugador restaurado en ",
		last_safe_position
	)
