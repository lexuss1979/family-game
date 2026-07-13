extends Node2D

enum GameState {
	FIND_REMOTE,
	RETURN_TO_SOFA,
	COMPLETE,
}

const PlayerScene := preload("res://scripts/player.gd")
const HOUSE := Rect2(80.0, 100.0, 1120.0, 540.0)
const WALL_THICKNESS := 24.0
const DOOR_POSITION := Vector2(640.0, 370.0)
const REMOTE_POSITION := Vector2(930.0, 320.0)
const SOFA_TARGET := Vector2(420.0, 245.0)

var player
var door_shape: CollisionShape2D
var status_label: Label
var prompt_label: Label
var character_button: Button
var state := GameState.FIND_REMOTE
var door_open := false
var elapsed_time := 0.0


func _ready() -> void:
	_create_world_collision()
	_create_player()
	_create_hud()
	queue_redraw()


func _process(delta: float) -> void:
	if state != GameState.COMPLETE:
		elapsed_time += delta
	_update_hud()


func _create_player() -> void:
	player = PlayerScene.new()
	player.name = "Father"
	player.position = Vector2(315.0, 430.0)
	player.z_index = 10
	player.interact_requested.connect(_on_interact_requested)
	player.character_changed.connect(_on_character_changed)
	add_child(player)


func _create_world_collision() -> void:
	# Outer walls.
	_add_static_rect(Vector2(640.0, HOUSE.position.y), Vector2(HOUSE.size.x, WALL_THICKNESS))
	_add_static_rect(Vector2(640.0, HOUSE.end.y), Vector2(HOUSE.size.x, WALL_THICKNESS))
	_add_static_rect(Vector2(HOUSE.position.x, 370.0), Vector2(WALL_THICKNESS, HOUSE.size.y))
	_add_static_rect(Vector2(HOUSE.end.x, 370.0), Vector2(WALL_THICKNESS, HOUSE.size.y))

	# Middle wall with a door-sized gap.
	_add_static_rect(Vector2(640.0, 215.0), Vector2(WALL_THICKNESS, 206.0))
	_add_static_rect(Vector2(640.0, 525.0), Vector2(WALL_THICKNESS, 206.0))

	var door_body := StaticBody2D.new()
	door_body.name = "DoorCollision"
	door_body.position = DOOR_POSITION
	door_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WALL_THICKNESS, 104.0)
	door_shape.shape = shape
	door_body.add_child(door_shape)
	add_child(door_body)

	# A few furniture collision shapes make the room feel tangible.
	_add_static_rect(Vector2(270.0, 205.0), Vector2(220.0, 82.0))
	_add_static_rect(Vector2(860.0, 205.0), Vector2(190.0, 92.0))
	_add_static_rect(Vector2(1020.0, 530.0), Vector2(230.0, 92.0))
	_add_static_rect(Vector2(810.0, 500.0), Vector2(105.0, 105.0))


func _add_static_rect(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var objective_panel := ColorRect.new()
	objective_panel.position = Vector2(24.0, 20.0)
	objective_panel.size = Vector2(650.0, 68.0)
	objective_panel.color = Color(0.12, 0.16, 0.12, 0.88)
	canvas.add_child(objective_panel)

	status_label = Label.new()
	status_label.position = Vector2(20.0, 10.0)
	status_label.size = Vector2(610.0, 50.0)
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color("fff4d6"))
	objective_panel.add_child(status_label)

	character_button = Button.new()
	character_button.position = Vector2(700.0, 20.0)
	character_button.size = Vector2(210.0, 68.0)
	character_button.focus_mode = Control.FOCUS_NONE
	character_button.add_theme_font_size_override("font_size", 17)
	character_button.pressed.connect(player.select_next_character)
	canvas.add_child(character_button)
	_on_character_changed(player.get_character_name())

	var controls := Label.new()
	controls.position = Vector2(930.0, 24.0)
	controls.size = Vector2(320.0, 56.0)
	controls.text = "Движение: WASD / стрелки\nДействие: E · Смена: Tab"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("4a382b"))
	canvas.add_child(controls)

	prompt_label = Label.new()
	prompt_label.position = Vector2(290.0, 654.0)
	prompt_label.size = Vector2(700.0, 46.0)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.06, 0.9))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(prompt_label)


func _on_character_changed(character_name: String) -> void:
	if character_button != null:
		character_button.text = "%s\nСменить [Tab]" % character_name


func _update_hud() -> void:
	match state:
		GameState.FIND_REMOTE:
			status_label.text = "Задача: найдите пульт в спальне"
		GameState.RETURN_TO_SOFA:
			status_label.text = "Пульт найден! Отнесите его к дивану"
		GameState.COMPLETE:
			status_label.text = "Готово за %.1f сек. Семейный вечер начинается!" % elapsed_time

	if state == GameState.COMPLETE:
		prompt_label.text = "Микро-демо завершено"
	elif state == GameState.FIND_REMOTE and player.position.distance_to(REMOTE_POSITION) < 70.0:
		prompt_label.text = "[E / Пробел] Поднять пульт"
	elif state == GameState.RETURN_TO_SOFA and player.position.distance_to(SOFA_TARGET) < 85.0:
		prompt_label.text = "[E / Пробел] Положить пульт возле дивана"
	elif player.position.distance_to(DOOR_POSITION) < 105.0:
		prompt_label.text = "[E / Пробел] %s дверь" % ("Закрыть" if door_open else "Открыть")
	else:
		prompt_label.text = ""


func _on_interact_requested() -> void:
	if state == GameState.FIND_REMOTE and player.position.distance_to(REMOTE_POSITION) < 70.0:
		state = GameState.RETURN_TO_SOFA
		queue_redraw()
		return

	if state == GameState.RETURN_TO_SOFA and player.position.distance_to(SOFA_TARGET) < 85.0:
		state = GameState.COMPLETE
		queue_redraw()
		return

	if player.position.distance_to(DOOR_POSITION) < 105.0:
		if door_open and absf(player.position.x - DOOR_POSITION.x) < 38.0:
			prompt_label.text = "Сначала отойдите от дверного проёма"
			return
		door_open = not door_open
		door_shape.set_deferred("disabled", door_open)
		queue_redraw()


func _draw() -> void:
	# Yard and house floor.
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("dce7c4"))
	draw_rect(Rect2(68.0, 88.0, 1144.0, 564.0), Color(0.25, 0.18, 0.12, 0.18))
	draw_rect(Rect2(92.0, 112.0, 536.0, 516.0), Color("d9a25f"))
	draw_rect(Rect2(652.0, 112.0, 536.0, 516.0), Color("a9ced0"))

	# Temporary repeating floor patterns.
	for y in range(128, 628, 32):
		draw_line(Vector2(92.0, y), Vector2(628.0, y), Color(0.43, 0.25, 0.12, 0.22), 2.0)
		var offset := 24 if ((y / 32) as int) % 2 == 0 else 0
		for x in range(116 + offset, 628, 64):
			draw_line(Vector2(x, y - 16), Vector2(x, y + 16), Color(0.43, 0.25, 0.12, 0.16), 1.0)
	for x in range(652, 1189, 48):
		draw_line(Vector2(x, 112.0), Vector2(x, 628.0), Color(0.16, 0.42, 0.45, 0.15), 1.0)
	for y in range(112, 629, 48):
		draw_line(Vector2(652.0, y), Vector2(1188.0, y), Color(0.16, 0.42, 0.45, 0.15), 1.0)

	# Room labels.
	draw_string(ThemeDB.fallback_font, Vector2(110.0, 145.0), "ГОСТИНАЯ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.28, 0.18, 0.1, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(675.0, 145.0), "СПАЛЬНЯ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.08, 0.27, 0.31, 0.55))

	# Furniture: sofa, table, wardrobe and bed.
	draw_rect(Rect2(160.0, 164.0, 220.0, 82.0), Color("426f99"), true)
	draw_rect(Rect2(170.0, 174.0, 96.0, 55.0), Color("5d8db8"), true)
	draw_rect(Rect2(274.0, 174.0, 96.0, 55.0), Color("5d8db8"), true)
	draw_circle(Vector2(420.0, 245.0), 42.0, Color(1.0, 0.82, 0.25, 0.18))
	draw_arc(Vector2(420.0, 245.0), 42.0, 0.0, TAU, 40, Color(1.0, 0.75, 0.18, 0.8), 3.0)

	draw_rect(Rect2(765.0, 159.0, 190.0, 92.0), Color("7c4b2a"), true)
	draw_rect(Rect2(778.0, 171.0, 164.0, 68.0), Color("80a9c7"), true)
	draw_rect(Rect2(905.0, 484.0, 230.0, 92.0), Color("f4e3bd"), true)
	draw_rect(Rect2(920.0, 499.0, 200.0, 62.0), Color("8fb2d2"), true)
	draw_rect(Rect2(758.0, 448.0, 105.0, 105.0), Color("916037"), true)
	draw_line(Vector2(810.0, 448.0), Vector2(810.0, 553.0), Color("59381f"), 3.0)

	# Walls.
	var wall_color := Color("f4ead8")
	var trim_color := Color("9a6439")
	draw_rect(Rect2(80.0, 88.0, 1120.0, WALL_THICKNESS), wall_color)
	draw_rect(Rect2(80.0, 628.0, 1120.0, WALL_THICKNESS), wall_color)
	draw_rect(Rect2(68.0, 100.0, WALL_THICKNESS, 540.0), wall_color)
	draw_rect(Rect2(1188.0, 100.0, WALL_THICKNESS, 540.0), wall_color)
	draw_rect(Rect2(628.0, 100.0, WALL_THICKNESS, 218.0), wall_color)
	draw_rect(Rect2(628.0, 422.0, WALL_THICKNESS, 218.0), wall_color)
	draw_line(Vector2(80.0, 112.0), Vector2(1200.0, 112.0), trim_color, 4.0)
	draw_line(Vector2(80.0, 628.0), Vector2(1200.0, 628.0), trim_color, 4.0)

	# Door: vertical when closed, swung into the bedroom when open.
	if door_open:
		draw_rect(Rect2(640.0, 318.0, 90.0, 15.0), Color("9a5b27"), true)
		draw_circle(Vector2(720.0, 325.5), 3.0, Color("f2c34f"))
	else:
		draw_rect(Rect2(628.0, 318.0, 24.0, 104.0), Color("9a5b27"), true)
		draw_circle(Vector2(643.0, 370.0), 3.0, Color("f2c34f"))

	# Collectible remote.
	if state == GameState.FIND_REMOTE:
		draw_circle(REMOTE_POSITION, 29.0, Color(1.0, 0.82, 0.25, 0.16))
		draw_rect(Rect2(REMOTE_POSITION - Vector2(10.0, 24.0), Vector2(20.0, 48.0)), Color("30343a"), true)
		for y in range(-14, 17, 10):
			draw_circle(REMOTE_POSITION + Vector2(0.0, y), 2.5, Color("d8dde3"))
	elif state == GameState.RETURN_TO_SOFA:
		# Tiny inventory marker above the player.
		draw_rect(Rect2(player.position + Vector2(-7.0, -112.0), Vector2(14.0, 28.0)), Color("30343a"), true)
	elif state == GameState.COMPLETE:
		draw_rect(Rect2(SOFA_TARGET + Vector2(-14.0, -8.0), Vector2(28.0, 14.0)), Color("30343a"), true)
