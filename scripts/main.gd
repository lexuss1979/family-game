extends Node2D

enum GameState {
	FIND_REMOTE,
	RETURN_TO_SOFA,
	COMPLETE,
}

const CharacterScene := preload("res://scripts/player.gd")
const ProceduralMusicScene := preload("res://scripts/procedural_music.gd")
const WORLD_SIZE := Vector2(2400.0, 1300.0)
const HOUSE := Rect2(80.0, 100.0, 2240.0, 1080.0)
const WALL_THICKNESS := 24.0
const DIVIDER_X := 1200.0
const DOOR_POSITION := Vector2(1200.0, 640.0)
const DOOR_GAP := 120.0
const REMOTE_POSITION := Vector2(1900.0, 350.0)
const SOFA_TARGET := Vector2(560.0, 280.0)
const NPC_SPECS := [
	{"index": 1, "name": "Mother", "position": Vector2(380.0, 800.0)},
	{"index": 2, "name": "Son", "position": Vector2(780.0, 390.0)},
	{"index": 3, "name": "Daughter", "position": Vector2(850.0, 850.0)},
	{"index": 4, "name": "Dog", "position": Vector2(1450.0, 480.0)},
	{"index": 5, "name": "Cat", "position": Vector2(1980.0, 520.0)},
	{"index": 6, "name": "Grandma1", "position": Vector2(1460.0, 850.0)},
	{"index": 7, "name": "Grandma2", "position": Vector2(2000.0, 780.0)},
]

var player
var npcs: Array[CharacterBody2D] = []
var music: AudioStreamPlayer
var door_shape: CollisionShape2D
var status_label: Label
var prompt_label: Label
var state := GameState.FIND_REMOTE
var door_open := false
var elapsed_time := 0.0


func _ready() -> void:
	_create_music()
	_create_world_collision()
	_create_characters()
	_create_hud()
	queue_redraw()


func _create_music() -> void:
	music = ProceduralMusicScene.new()
	music.name = "ProceduralMusic"
	add_child(music)


func _process(delta: float) -> void:
	if state != GameState.COMPLETE:
		elapsed_time += delta
	_update_hud()


func _create_characters() -> void:
	player = CharacterScene.new()
	player.name = "Father"
	player.configure(0, true)
	player.position = Vector2(350.0, 650.0)
	player.interact_requested.connect(_on_interact_requested)
	add_child(player)
	_attach_camera()

	for spec in NPC_SPECS:
		var npc = CharacterScene.new()
		npc.name = spec["name"]
		npc.configure(spec["index"], false)
		npc.position = spec["position"]
		add_child(npc)
		npcs.append(npc)


func _attach_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "PlayerCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	camera.enabled = true
	player.add_child(camera)


func _create_world_collision() -> void:
	# Outer walls.
	_add_static_rect(Vector2(1200.0, HOUSE.position.y), Vector2(HOUSE.size.x, WALL_THICKNESS))
	_add_static_rect(Vector2(1200.0, HOUSE.end.y), Vector2(HOUSE.size.x, WALL_THICKNESS))
	_add_static_rect(Vector2(HOUSE.position.x, 640.0), Vector2(WALL_THICKNESS, HOUSE.size.y))
	_add_static_rect(Vector2(HOUSE.end.x, 640.0), Vector2(WALL_THICKNESS, HOUSE.size.y))

	# Middle wall with a door-sized gap.
	_add_static_rect(Vector2(DIVIDER_X, 340.0), Vector2(WALL_THICKNESS, 480.0))
	_add_static_rect(Vector2(DIVIDER_X, 940.0), Vector2(WALL_THICKNESS, 480.0))

	var door_body := StaticBody2D.new()
	door_body.name = "DoorCollision"
	door_body.position = DOOR_POSITION
	door_shape = CollisionShape2D.new()
	var door_collision := RectangleShape2D.new()
	door_collision.size = Vector2(WALL_THICKNESS, DOOR_GAP)
	door_shape.shape = door_collision
	door_body.add_child(door_shape)
	add_child(door_body)

	# Furniture collision shapes.
	_add_static_rect(Vector2(350.0, 250.0), Vector2(320.0, 100.0))
	_add_static_rect(Vector2(900.0, 180.0), Vector2(180.0, 70.0))
	_add_static_rect(Vector2(480.0, 520.0), Vector2(140.0, 100.0))
	_add_static_rect(Vector2(1660.0, 260.0), Vector2(300.0, 120.0))
	_add_static_rect(Vector2(2150.0, 950.0), Vector2(180.0, 160.0))
	_add_static_rect(Vector2(1550.0, 950.0), Vector2(180.0, 120.0))


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

	var family_status := Label.new()
	family_status.position = Vector2(700.0, 24.0)
	family_status.size = Vector2(205.0, 56.0)
	family_status.text = "Папа: игрок\nОстальные: 7 NPC"
	family_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	family_status.add_theme_font_size_override("font_size", 16)
	family_status.add_theme_color_override("font_color", Color("4a382b"))
	canvas.add_child(family_status)

	var controls := Label.new()
	controls.position = Vector2(930.0, 24.0)
	controls.size = Vector2(320.0, 56.0)
	controls.text = "Движение: WASD / стрелки\nДействие: E · Музыка: M"
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
	elif state == GameState.FIND_REMOTE and player.position.distance_to(REMOTE_POSITION) < 75.0:
		prompt_label.text = "[E / Пробел] Поднять пульт"
	elif state == GameState.RETURN_TO_SOFA and player.position.distance_to(SOFA_TARGET) < 90.0:
		prompt_label.text = "[E / Пробел] Положить пульт возле дивана"
	elif player.position.distance_to(DOOR_POSITION) < 120.0:
		prompt_label.text = "[E / Пробел] %s дверь" % ("Закрыть" if door_open else "Открыть")
	else:
		prompt_label.text = ""


func _on_interact_requested() -> void:
	if state == GameState.FIND_REMOTE and player.position.distance_to(REMOTE_POSITION) < 75.0:
		state = GameState.RETURN_TO_SOFA
		queue_redraw()
		return

	if state == GameState.RETURN_TO_SOFA and player.position.distance_to(SOFA_TARGET) < 90.0:
		state = GameState.COMPLETE
		queue_redraw()
		return

	if player.position.distance_to(DOOR_POSITION) < 120.0:
		if door_open and absf(player.position.x - DOOR_POSITION.x) < 42.0:
			prompt_label.text = "Сначала отойдите от дверного проёма"
			return
		door_open = not door_open
		door_shape.set_deferred("disabled", door_open)
		queue_redraw()


func _draw() -> void:
	# Yard and enlarged house floor. Width and height are doubled, so each room
	# has four times the area of the first micro-demo.
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("dce7c4"))
	draw_rect(Rect2(68.0, 88.0, 2264.0, 1104.0), Color(0.25, 0.18, 0.12, 0.18))
	draw_rect(Rect2(92.0, 112.0, 1096.0, 1056.0), Color("d9a25f"))
	draw_rect(Rect2(1212.0, 112.0, 1096.0, 1056.0), Color("a9ced0"))

	# Temporary repeating floor patterns.
	for y in range(128, 1168, 32):
		draw_line(Vector2(92.0, y), Vector2(1188.0, y), Color(0.43, 0.25, 0.12, 0.22), 2.0)
		var offset := 24 if ((y / 32) as int) % 2 == 0 else 0
		for x in range(116 + offset, 1188, 64):
			draw_line(Vector2(x, y - 16), Vector2(x, y + 16), Color(0.43, 0.25, 0.12, 0.16), 1.0)
	for x in range(1212, 2309, 48):
		draw_line(Vector2(x, 112.0), Vector2(x, 1168.0), Color(0.16, 0.42, 0.45, 0.15), 1.0)
	for y in range(112, 1169, 48):
		draw_line(Vector2(1212.0, y), Vector2(2308.0, y), Color(0.16, 0.42, 0.45, 0.15), 1.0)

	# Room labels.
	draw_string(ThemeDB.fallback_font, Vector2(110.0, 145.0), "ГОСТИНАЯ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.28, 0.18, 0.1, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(1235.0, 145.0), "СПАЛЬНЯ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.08, 0.27, 0.31, 0.55))

	# Furniture: sofa, TV, table, bed, wardrobe and desk.
	draw_rect(Rect2(190.0, 200.0, 320.0, 100.0), Color("426f99"), true)
	draw_rect(Rect2(205.0, 215.0, 140.0, 68.0), Color("5d8db8"), true)
	draw_rect(Rect2(355.0, 215.0, 140.0, 68.0), Color("5d8db8"), true)
	draw_circle(SOFA_TARGET, 46.0, Color(1.0, 0.82, 0.25, 0.18))
	draw_arc(SOFA_TARGET, 46.0, 0.0, TAU, 40, Color(1.0, 0.75, 0.18, 0.8), 3.0)

	draw_rect(Rect2(810.0, 145.0, 180.0, 70.0), Color("7c4b2a"), true)
	draw_rect(Rect2(835.0, 155.0, 130.0, 45.0), Color("30343a"), true)
	draw_rect(Rect2(410.0, 470.0, 140.0, 100.0), Color("9a653a"), true)

	draw_rect(Rect2(1510.0, 200.0, 300.0, 120.0), Color("f4e3bd"), true)
	draw_rect(Rect2(1530.0, 220.0, 260.0, 80.0), Color("8fb2d2"), true)
	draw_rect(Rect2(2060.0, 870.0, 180.0, 160.0), Color("916037"), true)
	draw_line(Vector2(2150.0, 870.0), Vector2(2150.0, 1030.0), Color("59381f"), 3.0)
	draw_rect(Rect2(1460.0, 890.0, 180.0, 120.0), Color("a66f3d"), true)

	# Walls.
	var wall_color := Color("f4ead8")
	var trim_color := Color("9a6439")
	draw_rect(Rect2(80.0, 88.0, 2240.0, WALL_THICKNESS), wall_color)
	draw_rect(Rect2(80.0, 1168.0, 2240.0, WALL_THICKNESS), wall_color)
	draw_rect(Rect2(68.0, 100.0, WALL_THICKNESS, 1080.0), wall_color)
	draw_rect(Rect2(2308.0, 100.0, WALL_THICKNESS, 1080.0), wall_color)
	draw_rect(Rect2(1188.0, 100.0, WALL_THICKNESS, 480.0), wall_color)
	draw_rect(Rect2(1188.0, 700.0, WALL_THICKNESS, 480.0), wall_color)
	draw_line(Vector2(80.0, 112.0), Vector2(2320.0, 112.0), trim_color, 4.0)
	draw_line(Vector2(80.0, 1168.0), Vector2(2320.0, 1168.0), trim_color, 4.0)

	# Door: vertical when closed, swung into the bedroom when open.
	if door_open:
		draw_rect(Rect2(1200.0, 580.0, 110.0, 16.0), Color("9a5b27"), true)
		draw_circle(Vector2(1300.0, 588.0), 3.0, Color("f2c34f"))
	else:
		draw_rect(Rect2(1188.0, 580.0, 24.0, 120.0), Color("9a5b27"), true)
		draw_circle(Vector2(1203.0, 640.0), 3.0, Color("f2c34f"))

	# Collectible remote.
	if state == GameState.FIND_REMOTE:
		draw_circle(REMOTE_POSITION, 29.0, Color(1.0, 0.82, 0.25, 0.16))
		draw_rect(Rect2(REMOTE_POSITION - Vector2(10.0, 24.0), Vector2(20.0, 48.0)), Color("30343a"), true)
		for y in range(-14, 17, 10):
			draw_circle(REMOTE_POSITION + Vector2(0.0, y), 2.5, Color("d8dde3"))
	elif state == GameState.RETURN_TO_SOFA:
		draw_rect(Rect2(player.position + Vector2(-7.0, -112.0), Vector2(14.0, 28.0)), Color("30343a"), true)
	elif state == GameState.COMPLETE:
		draw_rect(Rect2(SOFA_TARGET + Vector2(-14.0, -8.0), Vector2(28.0, 14.0)), Color("30343a"), true)
