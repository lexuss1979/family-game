extends CharacterBody2D

signal interact_requested

const SPEED := 220.0
const NPC_SPEED := 95.0
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

enum AiState {
	IDLE,
	WALK,
}

var facing := Vector2.DOWN
var walking := false
var walk_time := 0.0
var character_sprite: Sprite2D
var character_index := 0
var player_controlled := true
var ai_state := AiState.IDLE
var ai_timer := 0.0
var ai_direction := Vector2.ZERO
var random := RandomNumberGenerator.new()


func configure(new_character_index: int, controlled: bool) -> void:
	character_index = clampi(new_character_index, 0, CHARACTER_TEXTURES.size() - 1)
	player_controlled = controlled


func _ready() -> void:
	random.seed = Time.get_ticks_usec() + get_instance_id() * 7919
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
	set_process_unhandled_input(player_controlled)
	if not player_controlled:
		_start_idle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := _player_direction() if player_controlled else _npc_direction(delta)

	walking = direction.length_squared() > 0.0
	if walking:
		direction = direction.normalized()
		facing = direction
		velocity = direction * (SPEED if player_controlled else NPC_SPEED)
		walk_time += delta * 10.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 8.0 * delta)

	move_and_slide()
	if not player_controlled and get_slide_collision_count() > 0:
		_start_idle(0.35, 1.0)
	z_index = 10 + int(position.y / 64.0)
	_update_animation_frame()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
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


func get_character_name() -> String:
	return CHARACTER_NAMES[character_index]


func _player_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	return direction


func _npc_direction(delta: float) -> Vector2:
	ai_timer -= delta
	if ai_timer <= 0.0:
		if ai_state == AiState.IDLE:
			_start_walk()
		else:
			_start_idle()
	return ai_direction if ai_state == AiState.WALK else Vector2.ZERO


func _start_idle(minimum_time := 1.5, maximum_time := 4.5) -> void:
	ai_state = AiState.IDLE
	ai_direction = Vector2.ZERO
	ai_timer = random.randf_range(minimum_time, maximum_time)


func _start_walk() -> void:
	var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	ai_state = AiState.WALK
	ai_direction = directions[random.randi_range(0, directions.size() - 1)]
	ai_timer = random.randf_range(0.9, 2.2)
