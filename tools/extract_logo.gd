extends SceneTree

const SOURCE_PATH := "res://design/logo.png"
const OUTPUT_PATH := "res://assets/ui/logo.png"


func _initialize() -> void:
	var logo := Image.load_from_file(SOURCE_PATH)
	if logo == null or logo.is_empty():
		_fail("Cannot load logo: %s" % SOURCE_PATH)
		return
	logo.convert(Image.FORMAT_RGBA8)

	_remove_connected_checkerboard(logo)
	_remove_large_enclosed_checkerboard_areas(logo)
	_keep_largest_component(logo)
	var bounds := _opaque_bounds(logo)
	if bounds.size == Vector2i.ZERO:
		_fail("Logo became empty after background removal")
		return

	var padded_bounds := bounds.grow(24).intersection(Rect2i(Vector2i.ZERO, logo.get_size()))
	var cropped := logo.get_region(padded_bounds)
	var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(output_file.get_base_dir())
	var result := cropped.save_png(output_file)
	if result != OK:
		_fail("Cannot save logo to %s (error %d)" % [output_file, result])
		return

	print("Saved transparent logo %dx%d -> %s" % [cropped.get_width(), cropped.get_height(), output_file])
	quit()


func _remove_connected_checkerboard(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var background := PackedByteArray()
	background.resize(width * height)
	var queue: Array[Vector2i] = []

	for x in width:
		_try_add_background(image, Vector2i(x, 0), background, queue)
		_try_add_background(image, Vector2i(x, height - 1), background, queue)
	for y in height:
		_try_add_background(image, Vector2i(0, y), background, queue)
		_try_add_background(image, Vector2i(width - 1, y), background, queue)

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
				_try_add_background(image, next, background, queue)

	for y in height:
		for x in width:
			if background[y * width + x] == 1:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
			else:
				var color := image.get_pixel(x, y)
				color.a = 1.0
				image.set_pixel(x, y, color)


func _try_add_background(
	image: Image,
	point: Vector2i,
	background: PackedByteArray,
	queue: Array[Vector2i]
) -> void:
	var index := point.y * image.get_width() + point.x
	if background[index] == 1:
		return
	if not _looks_like_checkerboard(image.get_pixelv(point)):
		return
	background[index] = 1
	queue.append(point)


func _looks_like_checkerboard(color: Color) -> bool:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	return darkest > 0.82 and brightest - darkest < 0.10


func _remove_large_enclosed_checkerboard_areas(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var neighbors: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	]

	for y in height:
		for x in width:
			var start := Vector2i(x, y)
			var start_index := y * width + x
			if visited[start_index] == 1:
				continue
			if image.get_pixelv(start).a < 0.5 or not _looks_like_strict_checkerboard(image.get_pixelv(start)):
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
					if visited[next_index] == 1:
						continue
					if image.get_pixelv(next).a < 0.5 or not _looks_like_strict_checkerboard(image.get_pixelv(next)):
						continue
					visited[next_index] = 1
					queue.append(next)

			if component.size() >= 500:
				for point in component:
					image.set_pixelv(point, Color(0.0, 0.0, 0.0, 0.0))


func _looks_like_strict_checkerboard(color: Color) -> bool:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	return darkest > 0.86 and brightest - darkest < 0.035


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
