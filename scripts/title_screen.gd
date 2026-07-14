extends CanvasLayer

signal game_started

const LOGO_TEXTURE := preload("res://assets/ui/logo.png")

var root_control: Control
var logo: TextureRect
var subtitle: Label
var start_button: Button
var starting := false


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	get_tree().paused = true
	call_deferred("_play_intro")


func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()
			_start_game()


func _build_interface() -> void:
	root_control = Control.new()
	root_control.name = "TitleLayout"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var gradient := Gradient.new()
	gradient.set_color(0, Color("fff4cf"))
	gradient.set_color(1, Color("b8d27d"))
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1280
	gradient_texture.height = 720
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)

	var background := TextureRect.new()
	background.name = "WarmBackground"
	background.texture = gradient_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(background)

	var bottom_glow := ColorRect.new()
	bottom_glow.name = "BottomGlow"
	bottom_glow.color = Color(1.0, 0.78, 0.25, 0.12)
	bottom_glow.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_glow.offset_top = -235.0
	bottom_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(bottom_glow)

	logo = TextureRect.new()
	logo.name = "GameLogo"
	logo.texture = LOGO_TEXTURE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.position = Vector2(-460.0, -345.0)
	logo.size = Vector2(920.0, 535.0)
	logo.pivot_offset = logo.size * 0.5
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(logo)

	subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Найдите всё нужное к семейному вечеру"
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-350.0, 176.0)
	subtitle.size = Vector2(700.0, 42.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("4f381e"))
	subtitle.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.7))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	root_control.add_child(subtitle)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "Начать игру"
	start_button.set_anchors_preset(Control.PRESET_CENTER)
	start_button.position = Vector2(-160.0, 230.0)
	start_button.size = Vector2(320.0, 68.0)
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.add_theme_font_size_override("font_size", 27)
	start_button.add_theme_color_override("font_color", Color("fff9e8"))
	start_button.add_theme_color_override("font_hover_color", Color.WHITE)
	start_button.add_theme_stylebox_override("normal", _button_style(Color("5f8f3b"), Color("365d25")))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("76aa4a"), Color("365d25")))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("4d7930"), Color("2a4c1c")))
	start_button.pressed.connect(_start_game)
	root_control.add_child(start_button)

	var input_hint := Label.new()
	input_hint.name = "InputHint"
	input_hint.text = "Enter / Пробел"
	input_hint.set_anchors_preset(Control.PRESET_CENTER)
	input_hint.position = Vector2(-160.0, 303.0)
	input_hint.size = Vector2(320.0, 28.0)
	input_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_hint.add_theme_font_size_override("font_size", 15)
	input_hint.add_theme_color_override("font_color", Color(0.25, 0.2, 0.12, 0.65))
	root_control.add_child(input_hint)


func _play_intro() -> void:
	logo.modulate = Color(1.0, 1.0, 1.0, 0.0)
	logo.scale = Vector2(0.82, 0.82)
	subtitle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	start_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var button_position := start_button.position
	start_button.position += Vector2(0.0, 24.0)

	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(logo, "modulate", Color.WHITE, 0.65).set_delay(0.08)
	tween.tween_property(logo, "scale", Vector2.ONE, 0.85).set_trans(Tween.TRANS_BACK)
	tween.tween_property(subtitle, "modulate", Color.WHITE, 0.5).set_delay(0.48)
	tween.tween_property(start_button, "modulate", Color.WHITE, 0.45).set_delay(0.68)
	tween.tween_property(start_button, "position", button_position, 0.5).set_delay(0.68).set_trans(Tween.TRANS_QUAD)
	start_button.grab_focus()


func _start_game() -> void:
	if starting:
		return
	starting = true
	start_button.disabled = true
	var tween := create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(root_control, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.45)
	tween.tween_property(logo, "scale", Vector2(1.06, 1.06), 0.45)
	await tween.finished
	get_tree().paused = false
	game_started.emit()
	queue_free()


func skip_intro_for_test() -> void:
	starting = true
	get_tree().paused = false
	game_started.emit()
	queue_free()


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.19, 0.13, 0.07, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 5.0)
	return style
