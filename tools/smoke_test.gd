extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("Cannot load main scene")
		return

	var main = packed_scene.instantiate()
	root.add_child(main)
	await process_frame

	if main.npcs.size() != 7:
		_fail("Expected 7 NPCs, got %d" % main.npcs.size())
		return
	if main.player.get_character_name() != "Папа":
		_fail("The controlled character must be Father")
		return
	if main.music == null or not main.music.playing:
		_fail("Procedural background music is not playing")
		return
	if AudioServer.get_bus_index(&"Music") < 0:
		_fail("Music audio bus was not created")
		return

	var characters: Array = [main.player]
	characters.append_array(main.npcs)
	for character in characters:
		if character.get_phrase_count() < 2 or character.speech_bubble == null:
			_fail("Character %s has no speech bubble phrases" % character.name)
			return

	var starting_positions: Array[Vector2] = []
	for npc in main.npcs:
		starting_positions.append(npc.position)

	# Every NPC idles for at most 4.5 seconds before its first short walk.
	await create_timer(6.0).timeout

	var moved_count := 0
	for index in main.npcs.size():
		var npc: CharacterBody2D = main.npcs[index]
		if npc.position.distance_to(starting_positions[index]) > 8.0:
			moved_count += 1
		if not Rect2(68.0, 88.0, 2264.0, 1104.0).has_point(npc.position):
			_fail("NPC %s left the house at %s" % [npc.name, npc.position])
			return

	if moved_count < 5:
		_fail("Only %d of 7 NPCs moved during the smoke test" % moved_count)
		return

	print("Smoke test passed: Father is controlled; %d/7 NPCs moved" % moved_count)
	main.queue_free()
	await process_frame
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
