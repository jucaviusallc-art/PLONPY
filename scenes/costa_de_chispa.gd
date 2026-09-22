extends Node3D

## ============================================================
## PLONPY — COSTA DE CHISPA 0.6
## Corrección del jugador invisible y de la plataforma flotante.
## ============================================================

func _ready() -> void:
	var cargando_partida := GameManager.is_loading_game

	GameManager.set_current_region("costa_de_chispa")

	if not cargando_partida:
		GameManager.current_scene = scene_file_path
		print("PLONPY: Nueva instancia de Costa de Chispa.")
	else:
		print("PLONPY: Costa de Chispa reconstruida desde partida guardada.")

	_preparar_terreno()

	var jugador := get_node_or_null("Jugador") as CharacterBody3D

	if jugador == null:
		push_error("PLONPY: No se encontró el nodo Jugador en Costa de Chispa.")
	else:
		# La escena original tenía Jugador = visible false.
		# Lo hacemos visible desde código para que no vuelva a ocurrir.
		jugador.visible = true

		if cargando_partida and GameManager.has_saved_position:
			jugador.global_position = GameManager.player_spawn_position
			print("PLONPY: Posición del jugador restaurada -> ", jugador.global_position)

		jugador.velocity = Vector3.ZERO
		jugador.floor_snap_length = 0.75
		jugador.apply_floor_snap()

	call_deferred("_notificar_carga_lista")
	print("PLONPY: Costa de Chispa lista.")


func _preparar_terreno() -> void:
	var suelo := get_node_or_null("SueloCosta") as CSGBox3D

	if suelo != null:
		# La Costa deja de ser una pequeña plataforma.
		suelo.size = Vector3(60.0, 0.5, 60.0)
		suelo.use_collision = true

	# Base profunda para que los bordes no terminen visualmente
	# en una lámina suspendida sobre el vacío.
	if get_node_or_null("BaseSolidaCosta") == null:
		var base := CSGBox3D.new()
		base.name = "BaseSolidaCosta"
		base.size = Vector3(60.0, 8.0, 60.0)
		base.position = Vector3(-4.0, -4.0, 0.0)
		base.use_collision = true

		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#17382C")
		material.roughness = 1.0
		base.material = material

		add_child(base)


func _notificar_carga_lista() -> void:
	var saver := get_node_or_null("/root/SaveManager")

	if saver != null and saver.has_method("finalizar_carga_escena"):
		saver.finalizar_carga_escena()


func guardar_partida() -> void:
	SaveManager.save_game()


func cargar_partida() -> void:
	SaveManager.load_game()
