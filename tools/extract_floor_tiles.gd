extends SceneTree

const OUTPUT_DIRECTORY := "res://assets/tiles/floors"
const SOURCE_SIZE := Vector2i(1774, 887)
const TILE_SIZE := Vector2i(887, 887)
const OUTPUT_SIZE := Vector2i(256, 256)

# Each generated sheet contains two square, edge-to-edge floor textures.
const FLOOR_SHEETS := [
	{
		"source": "res://design/floors.png",
		"left": "wood_light",
		"right": "kitchen_tile",
	},
	{
		"source": "res://design/bathroom-and-carpet.png",
		"left": "bathroom_tile",
		"right": "carpet",
	},
	{
		"source": "res://design/hall-floor-and-outdoor-floor.png",
		"left": "hall_tile",
		"right": "wood_dark",
	},
]


func _initialize() -> void:
	var output_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_result := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_result != OK:
		_fail("Cannot create output directory: %s" % output_directory)
		return

	var saved_count := 0
	for sheet_data in FLOOR_SHEETS:
		var source_path: String = sheet_data["source"]
		var source := Image.load_from_file(source_path)
		if source == null or source.is_empty():
			_fail("Cannot load floor sheet: %s" % source_path)
			return
		if source.get_size() != SOURCE_SIZE:
			_fail(
				"Unexpected size for %s: %s, expected %s"
				% [source_path, source.get_size(), SOURCE_SIZE]
			)
			return

		var names: Array[String] = [sheet_data["left"], sheet_data["right"]]
		for column in 2:
			var tile := source.get_region(
				Rect2i(Vector2i(column * TILE_SIZE.x, 0), TILE_SIZE)
			)
			# The generated square is a texture sample, not one in-game tile.
			# Downscaling makes boards and ceramic cells proportional to characters.
			tile.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var output_path := "%s/%s.png" % [OUTPUT_DIRECTORY, names[column]]
			var save_result := tile.save_png(ProjectSettings.globalize_path(output_path))
			if save_result != OK:
				_fail("Cannot save floor texture: %s (error %d)" % [output_path, save_result])
				return
			print("Saved %-14s -> %s" % [names[column], output_path])
			saved_count += 1

	print("Extracted %d floor textures (%dx%d each)" % [saved_count, OUTPUT_SIZE.x, OUTPUT_SIZE.y])
	quit()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
