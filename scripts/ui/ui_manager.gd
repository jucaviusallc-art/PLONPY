extends Node

## ============================================================
## PLONPY - UI MANAGER 0.5
## Interfaz global: menú principal tradicional, pausa, HUD,
## notificaciones y diálogos.
## Permanece activo entre cambios de escena.
## ============================================================

var layer: CanvasLayer
var main_menu: Control
var pause_menu: Control
var options_panel: Control
var hud: Control
var notification_panel: PanelContainer
var notification_title: Label
var notification_text: Label
var dialog_panel: PanelContainer
var dialog_title: Label
var dialog_text: Label

var notification_timer: float = 0.0
var dialog_timer: float = 0.0

var initialized: bool = false
var options_return_to_pause: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_build_interface")


func _process(delta: float) -> void:
	if notification_timer > 0.0:
		notification_timer -= delta
		if notification_timer <= 0.0 and notification_panel != null:
			notification_panel.visible = false

	if dialog_timer > 0.0:
		dialog_timer -= delta
		if dialog_timer <= 0.0 and dialog_panel != null:
			dialog_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not initialized:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if main_menu != null and main_menu.visible:
				return
			toggle_pause()


func _build_interface() -> void:
	if initialized:
		return

	layer = CanvasLayer.new()
	layer.name = "PLONPY_UI"
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_build_hud()
	_build_notification()
	_build_dialog()
	_build_main_menu()
	_build_pause_menu()
	_build_options()

	_connect_game_signals()

	initialized = true

	_refresh_hud()
	_update_continue_button()

	# ========================================================
	# MENÚ PRINCIPAL
	# ========================================================
	# IMPORTANTE:
	# El menú SIEMPRE aparece al iniciar PLONPY.
	#
	# La existencia de una partida guardada NO provoca
	# una carga automática por sorpresa.
	#
	# El jugador decide:
	# CONTINUAR -> cargar partida guardada
	# NUEVA PARTIDA -> comenzar desde cero
	# ========================================================

	print("PLONPY: UIManager mostrando menú principal.")

	_show_start_menu()

	print("PLONPY: UIManager 0.5 iniciado.")


func _connect_game_signals() -> void:
	var mission := get_node_or_null("/root/MissionManager")
	var game := get_node_or_null("/root/GameManager")
	var saver := get_node_or_null("/root/SaveManager")

	if mission != null:
		if mission.has_signal("mission_started") \
		and not mission.mission_started.is_connected(_on_mission_started):
			mission.mission_started.connect(_on_mission_started)

		if mission.has_signal("mission_completed") \
		and not mission.mission_completed.is_connected(_on_mission_completed):
			mission.mission_completed.connect(_on_mission_completed)

		if mission.has_signal("mission_progress_changed") \
		and not mission.mission_progress_changed.is_connected(_on_mission_progress):
			mission.mission_progress_changed.connect(_on_mission_progress)

	if game != null:
		if game.has_signal("nucleus_collected") \
		and not game.nucleus_collected.is_connected(_on_nucleus_collected):
			game.nucleus_collected.connect(_on_nucleus_collected)

		if game.has_signal("state_changed") \
		and not game.state_changed.is_connected(_on_state_changed):
			game.state_changed.connect(_on_state_changed)

	if saver != null:
		if saver.has_signal("game_saved") \
		and not saver.game_saved.is_connected(_on_game_saved):
			saver.game_saved.connect(_on_game_saved)

		if saver.has_signal("game_loaded") \
		and not saver.game_loaded.is_connected(_on_game_loaded):
			saver.game_loaded.connect(_on_game_loaded)


func _make_style(
	color: Color,
	radius: int = 16,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> StyleBoxFlat:

	var s := StyleBoxFlat.new()

	s.bg_color = color

	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius

	if border_width > 0:
		s.border_width_left = border_width
		s.border_width_right = border_width
		s.border_width_top = border_width
		s.border_width_bottom = border_width
		s.border_color = border_color

	return s


func _make_label(
	parent: Node,
	text_value: String,
	size: int,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:

	var label := Label.new()

	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	parent.add_child(label)

	return label


func _make_button(
	parent: Node,
	text_value: String,
	min_size := Vector2(300, 52)
) -> Button:

	var button := Button.new()

	button.text = text_value
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 18)

	button.focus_mode = Control.FOCUS_ALL

	button.add_theme_stylebox_override(
		"normal",
		_make_style(
			Color(0.08, 0.16, 0.19, 0.96),
			12,
			Color(0.25, 0.85, 0.95, 0.25),
			1
		)
	)

	button.add_theme_stylebox_override(
		"hover",
		_make_style(
			Color(0.10, 0.24, 0.28, 1.0),
			12,
			Color(0.35, 0.9, 1.0, 0.75),
			1
		)
	)

	button.add_theme_stylebox_override(
		"pressed",
		_make_style(
			Color(0.05, 0.12, 0.15, 1.0),
			12,
			Color(0.35, 0.9, 1.0, 0.9),
			1
		)
	)

	button.add_theme_stylebox_override(
		"disabled",
		_make_style(
			Color(0.05, 0.08, 0.09, 0.7),
			12
		)
	)

	parent.add_child(button)

	return button


func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUDDefinitivo"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE

	layer.add_child(hud)

	var stats := PanelContainer.new()
	stats.name = "Stats"
	stats.position = Vector2(24, 24)
	stats.size = Vector2(300, 190)

	stats.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.025, 0.08, 0.10, 0.90),
			18,
			Color(0.25, 0.85, 0.95, 0.28),
			1
		)
	)

	hud.add_child(stats)

	var margin := MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)

	stats.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	margin.add_child(box)

	_make_label(box, "PLONPY", 25)
	_make_label(box, "Costa de Chispa", 12)
	_make_label(box, "", 3)
	_make_label(box, "Núcleos", 12)

	var values := _make_label(box, "", 16)
	values.name = "StatsValues"


	var mission_card := PanelContainer.new()
	mission_card.name = "MissionCard"
	mission_card.position = Vector2(24, 228)
	mission_card.size = Vector2(430, 150)

	mission_card.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.025, 0.08, 0.10, 0.88),
			18,
			Color(0.40, 0.85, 0.65, 0.25),
			1
		)
	)

	hud.add_child(mission_card)

	var mm := MarginContainer.new()

	mm.add_theme_constant_override("margin_left", 18)
	mm.add_theme_constant_override("margin_right", 18)
	mm.add_theme_constant_override("margin_top", 14)
	mm.add_theme_constant_override("margin_bottom", 14)

	mission_card.add_child(mm)

	var mission_box := VBoxContainer.new()
	mission_box.add_theme_constant_override("separation", 4)

	mm.add_child(mission_box)

	_make_label(mission_box, "MISIÓN", 11)

	var mission_label := _make_label(mission_box, "", 16)
	mission_label.name = "MissionText"


	var controls := _make_label(
		hud,
		"WASD  Mover      ESC  Pausa      G  Guardar      L  Cargar",
		12
	)

	controls.position = Vector2(24, 650)
	controls.size = Vector2(500, 28)
	controls.modulate = Color(0.78, 0.88, 0.90, 0.82)


func _build_notification() -> void:
	notification_panel = PanelContainer.new()
	notification_panel.name = "Notification"
	notification_panel.position = Vector2(300, 535)
	notification_panel.size = Vector2(552, 92)

	notification_panel.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.025, 0.08, 0.10, 0.96),
			16,
			Color(0.20, 0.82, 0.94, 0.70),
			2
		)
	)

	notification_panel.visible = false
	layer.add_child(notification_panel)

	var m := MarginContainer.new()

	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)

	notification_panel.add_child(m)

	var box := VBoxContainer.new()
	m.add_child(box)

	notification_title = _make_label(box, "NOVEDAD", 11)
	notification_title.modulate = Color(0.35, 0.88, 1.0)

	notification_text = _make_label(
		box,
		"",
		18,
		HORIZONTAL_ALIGNMENT_CENTER
	)


func _build_dialog() -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.name = "Dialogue"
	dialog_panel.position = Vector2(140, 505)
	dialog_panel.size = Vector2(872, 125)

	dialog_panel.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.015, 0.045, 0.06, 0.97),
			20,
			Color(0.55, 0.95, 0.85, 0.55),
			2
		)
	)

	dialog_panel.visible = false
	layer.add_child(dialog_panel)

	var m := MarginContainer.new()

	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)

	dialog_panel.add_child(m)

	var box := VBoxContainer.new()
	m.add_child(box)

	dialog_title = _make_label(box, "", 13)
	dialog_title.modulate = Color(0.55, 0.95, 0.85)

	dialog_text = _make_label(box, "", 19)


func _build_main_menu() -> void:
	main_menu = _overlay(
		"MainMenu",
		Color(0.01, 0.025, 0.035, 0.96)
	)

	var center := VBoxContainer.new()

	center.position = Vector2(356, 92)
	center.size = Vector2(440, 500)
	center.add_theme_constant_override("separation", 12)

	main_menu.add_child(center)

	var title := _make_label(
		center,
		"PLONPY",
		58,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.custom_minimum_size = Vector2(440, 90)
	title.modulate = Color(0.45, 0.94, 1.0)

	var subtitle := _make_label(
		center,
		"EL MUNDO QUE RESPIRA",
		15,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.custom_minimum_size = Vector2(440, 35)
	subtitle.modulate = Color(0.65, 0.86, 0.86)

	_make_label(center, "", 18)

	var new_game := _make_button(
		center,
		"NUEVA PARTIDA"
	)

	new_game.pressed.connect(_on_new_game_pressed)

	var continue_game := _make_button(
		center,
		"CONTINUAR"
	)

	continue_game.name = "ContinueButton"
	continue_game.pressed.connect(_on_continue_pressed)

	var options := _make_button(
		center,
		"OPCIONES"
	)

	options.pressed.connect(_on_options_pressed)

	var exit := _make_button(
		center,
		"SALIR"
	)

	exit.pressed.connect(_on_exit_pressed)

	var hint := _make_label(
		center,
		"VYRA espera. Algo antiguo está despertando.",
		12,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hint.custom_minimum_size = Vector2(440, 45)
	hint.modulate = Color(0.55, 0.70, 0.72)


func _build_pause_menu() -> void:
	pause_menu = _overlay(
		"PauseMenu",
		Color(0.01, 0.025, 0.035, 0.72)
	)

	var panel := PanelContainer.new()

	panel.position = Vector2(405, 105)
	panel.size = Vector2(342, 430)

	panel.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.025, 0.08, 0.10, 0.98),
			22,
			Color(0.25, 0.85, 0.95, 0.35),
			1
		)
	)

	pause_menu.add_child(panel)

	var box := VBoxContainer.new()

	box.position = Vector2(28, 26)
	box.size = Vector2(286, 370)
	box.add_theme_constant_override("separation", 12)

	panel.add_child(box)

	_make_label(
		box,
		"PAUSA",
		32,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_make_label(box, "", 4)

	var resume := _make_button(
		box,
		"CONTINUAR",
		Vector2(286, 50)
	)

	resume.pressed.connect(_on_resume_pressed)

	var save := _make_button(
		box,
		"GUARDAR PARTIDA",
		Vector2(286, 50)
	)

	save.pressed.connect(_on_pause_save_pressed)

	var options := _make_button(
		box,
		"OPCIONES",
		Vector2(286, 50)
	)

	options.pressed.connect(_on_options_pressed)

	var menu := _make_button(
		box,
		"MENÚ PRINCIPAL",
		Vector2(286, 50)
	)

	menu.pressed.connect(_on_main_menu_from_pause)

	_make_label(
		box,
		"ESC para volver",
		12,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	pause_menu.visible = false


func _build_options() -> void:
	options_panel = _overlay(
		"Options",
		Color(0.01, 0.025, 0.035, 0.92)
	)

	var panel := PanelContainer.new()

	panel.position = Vector2(330, 110)
	panel.size = Vector2(492, 420)

	panel.add_theme_stylebox_override(
		"panel",
		_make_style(
			Color(0.025, 0.08, 0.10, 0.98),
			22,
			Color(0.25, 0.85, 0.95, 0.35),
			1
		)
	)

	options_panel.add_child(panel)

	var box := VBoxContainer.new()

	box.position = Vector2(32, 28)
	box.size = Vector2(428, 355)
	box.add_theme_constant_override("separation", 12)

	panel.add_child(box)

	_make_label(
		box,
		"OPCIONES",
		30,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_make_label(box, "Interfaz", 13)

	var interface_info := _make_label(
		box,
		"Modo de control: teclado WASD\nResolución: se adapta automáticamente a la ventana.",
		16
	)

	interface_info.custom_minimum_size = Vector2(428, 70)

	_make_label(box, "Audio", 13)

	var audio_info := _make_label(
		box,
		"El sistema de audio se integrará en la fase de SFX y música.",
		16
	)

	audio_info.custom_minimum_size = Vector2(428, 55)

	var back := _make_button(
		box,
		"VOLVER",
		Vector2(428, 52)
	)

	back.pressed.connect(_close_options)

	options_panel.visible = false


func _overlay(node_name: String, color: Color) -> Control:
	var overlay := Control.new()

	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var background := ColorRect.new()

	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	overlay.add_child(background)
	layer.add_child(overlay)

	return overlay


func _show_start_menu() -> void:
	if main_menu == null:
		return

	pause_menu.visible = false
	options_panel.visible = false
	main_menu.visible = true

	get_tree().paused = true

	_update_continue_button()


func _on_new_game_pressed() -> void:
	print("PLONPY: Nueva Partida solicitada por el usuario.")

	var saver := get_node_or_null("/root/SaveManager")

	if saver != null and saver.has_method("new_game"):
		saver.new_game()
	elif saver != null and saver.has_method("delete_save"):
		saver.delete_save()
		var game := get_node_or_null("/root/GameManager")
		if game != null and game.has_method("start_new_game"):
			game.start_new_game()
	else:
		show_notification(
			"PARTIDA",
			"El sistema de nueva partida no está disponible."
		)
		return

	get_tree().paused = false

	if main_menu != null:
		main_menu.visible = false

	show_dialogue(
		"VYRA",
		"El mundo que respira... Algo antiguo ha comenzado a recordarte.",
		4.5
	)


func _on_continue_pressed() -> void:
	var saver := get_node_or_null("/root/SaveManager")

	if saver == null or not saver.has_method("load_game"):
		show_notification(
			"PARTIDA",
			"El sistema de guardado no está disponible."
		)
		return

	get_tree().paused = false

	main_menu.visible = false

	saver.load_game()


func _on_options_pressed() -> void:
	options_return_to_pause = (
		pause_menu != null
		and pause_menu.visible
	)

	main_menu.visible = false
	pause_menu.visible = false
	options_panel.visible = true

	get_tree().paused = true


func _close_options() -> void:
	options_panel.visible = false

	if options_return_to_pause:
		pause_menu.visible = true
		get_tree().paused = true
	else:
		main_menu.visible = true
		get_tree().paused = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func toggle_pause() -> void:
	if options_panel != null and options_panel.visible:
		_close_options()
		return

	if main_menu != null and main_menu.visible:
		return

	if pause_menu.visible:
		_on_resume_pressed()
	else:
		pause_menu.visible = true
		get_tree().paused = true


func _on_resume_pressed() -> void:
	pause_menu.visible = false
	get_tree().paused = false


func _on_pause_save_pressed() -> void:
	var saver := get_node_or_null("/root/SaveManager")

	if saver != null and saver.has_method("save_game"):
		saver.save_game()

	show_notification(
		"PARTIDA GUARDADA",
		"Tu progreso ha quedado registrado.",
		2.5
	)


func _on_main_menu_from_pause() -> void:
	pause_menu.visible = false
	_show_start_menu()


func _update_continue_button() -> void:
	if main_menu == null:
		return

	var button := main_menu.get_node_or_null(
		"ContinueButton"
	) as Button

	if button == null:
		return

	var saver := get_node_or_null("/root/SaveManager")

	button.disabled = (
		saver == null
		or not saver.has_method("has_save")
		or not saver.has_save()
	)


func show_notification(
	title: String,
	text: String,
	duration: float = 3.0
) -> void:

	if notification_panel == null:
		return

	if dialog_panel != null:
		dialog_panel.visible = false

	notification_title.text = title
	notification_text.text = text

	notification_panel.visible = true
	notification_timer = duration


func show_dialogue(
	speaker: String,
	text: String,
	duration: float = 4.0
) -> void:

	if dialog_panel == null:
		return

	dialog_title.text = speaker
	dialog_text.text = text

	dialog_panel.visible = true
	dialog_timer = duration


func _refresh_hud() -> void:
	if hud == null:
		return

	var game := get_node_or_null("/root/GameManager")

	if game == null:
		return

	var values := hud.get_node_or_null(
		"Stats/StatsValues"
	) as Label

	if values != null:
		values.text = (
			"Núcleos: %d\nNivel: %d    XP: %d\nCHISPA: %d"
			% [
				game.collected_nuclei.size(),
				game.nivel,
				game.xp,
				game.chispa
			]
		)

	var mission := get_node_or_null("/root/MissionManager")

	var mission_text := hud.get_node_or_null(
		"MissionCard/MissionText"
	) as Label

	if (
		mission != null
		and mission_text != null
		and mission.has_method("get_mission_text")
	):
		mission_text.text = mission.get_mission_text()


func _on_state_changed() -> void:
	_refresh_hud()


func _on_mission_started(_mission_id: String) -> void:
	_refresh_hud()


func _on_mission_progress(
	_mission_id: String,
	_current: int,
	_total: int
) -> void:
	_refresh_hud()


func _on_mission_completed(mission_id: String) -> void:
	_refresh_hud()

	var mission := get_node_or_null("/root/MissionManager")
	var reward := ""

	if mission != null and mission.has_method("get_reward_text"):
		reward = " · " + mission.get_reward_text(mission_id)

	show_notification(
		"MISIÓN COMPLETADA",
		"%s%s" % [mission_id, reward],
		4.0
	)


func _on_nucleus_collected(nucleus_id: String) -> void:
	_refresh_hud()

	show_notification(
		"NÚCLEO DESCUBIERTO",
		nucleus_id.replace("_", " ").capitalize(),
		3.5
	)


func _on_game_saved() -> void:
	_update_continue_button()


func _on_game_loaded() -> void:
	if main_menu != null:
		main_menu.visible = false

	if pause_menu != null:
		pause_menu.visible = false

	get_tree().paused = false

	_update_continue_button()
	_refresh_hud()

	print("PLONPY: UIManager recibió game_loaded.")


func notify_discovery(title: String, text: String) -> void:
	show_notification(
		"DESCUBRIMIENTO",
		text if not text.is_empty() else title,
		3.2
	)
