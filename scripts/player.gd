extends CharacterBody2D

signal interact_requested
signal character_changed(character_name: String)

const SPEED := 220.0
const FRAME_SIZE := Vector2(160.0, 160.0)
const CHARACTER_TEXTURES := [
	preload("res://assets/characters/father.png"),
	preload("res://assets/characters/mother.png"),
	preload("res://assets/characters/son.png"),
	preload("res://assets/characters/daughter.png"),
	preload("res://assets/characters/dog.png"),
	preload("res://assets/characters/cat.png"),
	preload("res://assets/characters/grandma_1.png"),
	preload("res://assets/characters/grandma_2.png"),
]
const CHARACTER_NAMES := [
	"Папа",
	"Мама",
	"Сын",
	"Дочь",
	"Собака",
	"Кошка",
	"Бабушка №1",
	"Бабушка №2",
]

var facing := Vector2.DOWN
var walking := false
var walk_time := 0.0
var character_sprite: Sprite2D
var character_index := 0


func _ready() -> void:
	character_sprite = Sprite2D.new()
	character_sprite.name = "CharacterSprite"
	character_sprite.texture = CHARACTER_TEXTURES[character_index]
	character_sprite.region_enabled = true
	character_sprite.region_rect = Rect2(Vector2.ZERO, FRAME_SIZE)
	character_sprite.position = Vector2(0.0, -50.0)
	character_sprite.scale = Vector2(0.62, 0.62)
	character_sprite.z_index = 1
	add_child(character_sprite)

	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	collider.shape = shape
	add_child(collider)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	walking = direction.length_squared() > 0.0
	if walking:
		direction = direction.normalized()
		facing = direction
		velocity = direction * SPEED
		walk_time += delta * 10.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 8.0 * delta)

	move_and_slide()
	_update_animation_frame()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			select_next_character()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			interact_requested.emit()
			get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(Vector2(0.0, 5.0), 22.0, Color(0.18, 0.13, 0.1, 0.22))


func _update_animation_frame() -> void:
	if not walking:
		_set_frame(0)
		return

	var phase := int(walk_time) % 2
	var first_frame := 3
	if absf(facing.x) > absf(facing.y):
		first_frame = 5 if facing.x < 0.0 else 7
	elif facing.y < 0.0:
		first_frame = 1

	_set_frame(first_frame + phase)


func _set_frame(frame_index: int) -> void:
	character_sprite.region_rect = Rect2(
		Vector2(frame_index * FRAME_SIZE.x, 0.0),
		FRAME_SIZE
	)


func select_next_character() -> void:
	character_index = (character_index + 1) % CHARACTER_TEXTURES.size()
	character_sprite.texture = CHARACTER_TEXTURES[character_index]
	_set_frame(0)
	character_changed.emit(get_character_name())


func get_character_name() -> String:
	return CHARACTER_NAMES[character_index]
