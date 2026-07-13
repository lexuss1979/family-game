extends SceneTree

const SOURCE_PATH := "res://design/personage.png"
const OUTPUT_DIRECTORY := "res://assets/characters"
const FRAME_SIZE := Vector2i(160, 160)

# All atlases use the same frame order:
# idle, up 1/2, down 1/2, left 1/2, right 1/2.
const CHARACTER_ROWS := [
	{"name": "father", "top": 35, "height": 150},
	{"name": "mother", "top": 180, "height": 146},
	{"name": "son", "top": 330, "height": 130},
	{"name": "daughter", "top": 463, "height": 137},
	{"name": "dog", "top": 600, "height": 120, "mirror_right_2": true},
	{"name": "cat", "top": 716, "height": 110, "mirror_right_2": true},
	{"name": "grandma_1", "top": 823, "height": 125},
	{"name": "grandma_2", "top": 949, "height": 135},
]

# Side-facing animals are wider than people, so the last columns deliberately
# use wider source rectangles. Foreground is centered in the 160 px output cell.
const FRAME_COLUMNS := [
	Vector2i(175, 140),
	Vector2i(300, 140),
	Vector2i(430, 140),
	Vector2i(560, 140),
	Vector2i(690, 140),
	Vector2i(835, 147),
	Vector2i(982, 143),
	Vector2i(1125, 140),
	Vector2i(1260, 175),
]


func _initialize() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source == null or source.is_empty():
		_fail("Cannot load source image: %s" % SOURCE_PATH)
		return

	var output_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_result := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_result != OK:
		_fail("Cannot create output directory: %s" % output_directory)
		return

	for character_data in CHARACTER_ROWS:
		var character_name: String = character_data["name"]
		var row_top: int = character_data["top"]
		var row_height: int = character_data["height"]
		var mirror_right_2: bool = character_data.get("mirror_right_2", false)
		var atlas := _build_atlas(
			source,
			character_name,
			row_top,
			row_height,
			mirror_right_2
		)
		if atlas == null:
			return

		var output_path := "%s/%s.png" % [OUTPUT_DIRECTORY, character_name]
		var output_file := ProjectSettings.globalize_path(output_path)
		var save_result := atlas.save_png(output_file)
		if save_result != OK:
			_fail("Cannot save atlas: %s (error %d)" % [output_file, save_result])
			return
		print("Saved %-9s -> %s" % [character_name, output_file])

	print("Extracted %d characters, %d frames each" % [CHARACTER_ROWS.size(), FRAME_COLUMNS.size()])
	quit()


func _build_atlas(
	source: Image,
	character_name: String,
	row_top: int,
	row_height: int,
	mirror_right_2: bool
) -> Image:
	var atlas := Image.create_empty(
		FRAME_SIZE.x * FRAME_COLUMNS.size(),
		FRAME_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	atlas.fill(Color(0.0, 0.0, 0.0, 0.0))

	for frame_index in FRAME_COLUMNS.size():
		# The source sheet accidentally contains a left-facing RIGHT 2 pose for
		# both animals. Mirror LEFT 2 to preserve the second stride phase.
		var source_frame_index := 6 if mirror_right_2 and frame_index == 8 else frame_index
		var column: Vector2i = FRAME_COLUMNS[source_frame_index]
		var source_rect := Rect2i(column.x, row_top, column.y, row_height)
		var frame := _extract_foreground(source, source_rect)
		_keep_largest_component(frame)
		if mirror_right_2 and frame_index == 8:
			frame.flip_x()
		var bounds := _opaque_bounds(frame)
		if bounds.size == Vector2i.ZERO:
			_fail("%s frame %d is empty" % [character_name, frame_index])
			return null
		if bounds.size.x > FRAME_SIZE.x - 8 or bounds.size.y > FRAME_SIZE.y - 8:
			_fail(
				"%s frame %d does not fit the target cell: %s"
				% [character_name, frame_index, bounds]
			)
			return null

		# Center horizontally and align every pose to the same baseline.
		var destination := Vector2i(
			frame_index * FRAME_SIZE.x + (FRAME_SIZE.x - bounds.size.x) / 2,
			FRAME_SIZE.y - bounds.size.y - 4
		)
		atlas.blit_rect(frame, bounds, destination)

	return atlas


func _extract_foreground(source: Image, source_rect: Rect2i) -> Image:
	var frame := source.get_region(source_rect)
	frame.convert(Image.FORMAT_RGBA8)
	var width := frame.get_width()
	var height := frame.get_height()
	var background := PackedByteArray()
	background.resize(width * height)
	var queue: Array[Vector2i] = []

	for x in width:
		_try_add_background(frame, Vector2i(x, 0), background, queue)
		_try_add_background(frame, Vector2i(x, height - 1), background, queue)
	for y in height:
		_try_add_background(frame, Vector2i(0, y), background, queue)
		_try_add_background(frame, Vector2i(width - 1, y), background, queue)

	var cursor := 0
	var neighbors: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	]
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		for offset in neighbors:
			var next: Vector2i = point + offset
			if next.x >= 0 and next.x < width and next.y >= 0 and next.y < height:
				_try_add_background(frame, next, background, queue)

	for y in height:
		for x in width:
			if background[y * width + x] == 1:
				frame.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
			else:
				var color := frame.get_pixel(x, y)
				color.a = 1.0
				frame.set_pixel(x, y, color)

	return frame


func _try_add_background(
	frame: Image,
	point: Vector2i,
	background: PackedByteArray,
	queue: Array[Vector2i]
) -> void:
	var index := point.y * frame.get_width() + point.x
	if background[index] == 1:
		return
	if not _looks_like_sheet_background(frame.get_pixelv(point)):
		return
	background[index] = 1
	queue.append(point)


func _looks_like_sheet_background(color: Color) -> bool:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	var neutral := brightest - darkest < 0.13
	return neutral and darkest > 0.78


func _keep_largest_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest_component: Array[Vector2i] = []
	var neighbors: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]

	for y in height:
		for x in width:
			var start := Vector2i(x, y)
			var start_index := y * width + x
			if visited[start_index] == 1 or image.get_pixelv(start).a < 0.5:
				continue

			var component: Array[Vector2i] = []
			var queue: Array[Vector2i] = [start]
			visited[start_index] = 1
			var cursor := 0
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				component.append(point)
				for offset in neighbors:
					var next: Vector2i = point + offset
					if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
						continue
					var next_index := next.y * width + next.x
					if visited[next_index] == 1 or image.get_pixelv(next).a < 0.5:
						continue
					visited[next_index] = 1
					queue.append(next)

			if component.size() > largest_component.size():
				largest_component = component

	var keep := PackedByteArray()
	keep.resize(width * height)
	for point in largest_component:
		keep[point.y * width + point.x] = 1

	for y in height:
		for x in width:
			if image.get_pixel(x, y).a >= 0.5 and keep[y * width + x] == 0:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))


func _opaque_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x)
				maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
