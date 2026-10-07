extends SceneTree
## Art-sheet processor for Office Hearts.
## Splits a generated sheet into a cols x rows grid, keys out the flat
## background, trims to the visible content, and saves PNGs. No image
## libraries needed.
##
## Usage:
##   godot --headless --path . --script res://tools/process_art.gd -- \
##     --in <sheet.png> --out <abs dir> --names a,b,c,d \
##     [--key white|green|none] [--trim 1] [--pad 8] [--cols 2] [--rows 2]
##     [--fade-bottom 0.15]
##
## Cell order: left-to-right, top-to-bottom (row-major).

const WHITE_T := 0.88   # min channel value for "background white"
const SAT_T := 0.07     # max (max-min) channel spread for "not coloured"

var _w := 0
var _h := 0
var _white_t := 0.88
var _sat_t := 0.07
var _visited := PackedByteArray()
var _stack: Array[int] = []


func _initialize() -> void:
	var a := _parse_args(OS.get_cmdline_user_args())
	var src: String = a.get("in", "")
	var out_dir: String = a.get("out", "")
	if src == "" or out_dir == "":
		printerr("usage: --in <sheet.png> --out <dir> --names a,b,c,d [--key white|green|none] [--trim 1] [--pad 8] [--cols 2] [--rows 2]")
		quit(1)
		return

	var key_mode: String = a.get("key", "none")
	_white_t = float(a.get("white-t", "0.88"))
	_sat_t = float(a.get("sat-t", "0.07"))
	var do_trim: bool = a.get("trim", "1") == "1"
	var pad: int = int(a.get("pad", "8"))
	var cols: int = int(a.get("cols", "2"))
	var rows: int = int(a.get("rows", "2"))
	var fade: float = float(a.get("fade-bottom", "0"))

	var names: Array[String] = []
	if a.has("names"):
		for n in String(a["names"]).split(",", false):
			names.append(n.strip_edges())

	var bytes := FileAccess.get_file_as_bytes(src)
	if bytes.is_empty():
		printerr("FAIL cannot read ", src)
		quit(1)
		return
	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if bytes.size() > 4 and bytes[0] == 0x89 and bytes[1] == 0x50 and bytes[2] == 0x4E and bytes[3] == 0x47:
		err = img.load_png_from_buffer(bytes)
	elif bytes.size() > 3 and bytes[0] == 0xFF and bytes[1] == 0xD8 and bytes[2] == 0xFF:
		err = img.load_jpg_from_buffer(bytes)
	elif bytes.size() > 12 and bytes[8] == 0x57 and bytes[9] == 0x45 and bytes[10] == 0x42 and bytes[11] == 0x50:
		err = img.load_webp_from_buffer(bytes)
	else:
		err = img.load(src)
	if err != OK:
		printerr("FAIL cannot decode ", src, " err=", err)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	var cw := img.get_width() / cols
	var ch := img.get_height() / rows
	DirAccess.make_dir_recursive_absolute(out_dir)

	var done := 0
	var i := 0
	for gy in rows:
		for gx in cols:
			if i >= names.size():
				break
			var cell := img.get_region(Rect2i(gx * cw, gy * ch, cw, ch))
			cell = _duplicate_image(cell)
			if key_mode == "white":
				_key_white(cell, a.get("nobottom", "0") != "1")
			elif key_mode == "green":
				_key_green(cell)
			if do_trim:
				cell = _trim(cell, pad)
			if fade > 0.0:
				cell = _fade_bottom(cell, fade)
			if a.has("qa-bg"):
				var bg := Color(String(a["qa-bg"]))
				bg.a = 1.0
				var base := Image.create_empty(cell.get_width(), cell.get_height(), false, Image.FORMAT_RGBA8)
				base.fill(bg)
				base.blend_rect(cell, Rect2i(0, 0, cell.get_width(), cell.get_height()), Vector2i.ZERO)
				cell = base
			var out := out_dir.path_join(names[i] + ".png")
			var e := cell.save_png(out)
			if e != OK:
				printerr("FAIL save ", out, " err=", e)
			else:
				print("OK ", names[i], " -> ", cell.get_width(), "x", cell.get_height())
				done += 1
			i += 1

	print("DONE ", done, " image(s) from ", src)
	quit(0)


func _parse_args(raw: PackedStringArray) -> Dictionary:
	var a := {}
	var i := 0
	while i < raw.size():
		var k := raw[i]
		if k.begins_with("--"):
			var val := "1"
			if i + 1 < raw.size() and not raw[i + 1].begins_with("--"):
				val = raw[i + 1]
				i += 1
			a[k.substr(2)] = val
		i += 1
	return a


func _duplicate_image(src: Image) -> Image:
	## get_region returns a view-like copy; make it independent and writable.
	var out := Image.create_empty(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out


func _is_bg_white(c: Color) -> bool:
	if c.a < 0.5:
		return false
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	return mn >= _white_t and (mx - mn) <= _sat_t


func _try_push(x: int, y: int, img: Image) -> void:
	if x < 0 or y < 0 or x >= _w or y >= _h:
		return
	var p := y * _w + x
	if _visited[p] == 1:
		return
	if not _is_bg_white(img.get_pixel(x, y)):
		return
	_visited[p] = 1
	_stack.append(p)


func _key_white(img: Image, seed_bottom: bool = true) -> void:
	## Flood fill the near-white background inward from the borders so that
	## white clothing inside the silhouette is preserved. When a character is
	## cropped by the bottom edge (bust sprites), its white shirt merges with
	## the background there, so seed_bottom must be false to avoid eating it.
	_w = img.get_width()
	_h = img.get_height()
	_visited = PackedByteArray()
	_visited.resize(_w * _h)
	_stack.clear()

	for x in _w:
		_try_push(x, 0, img)
		if seed_bottom:
			_try_push(x, _h - 1, img)
	for y in _h:
		_try_push(0, y, img)
		_try_push(_w - 1, y, img)

	while not _stack.is_empty():
		var p: int = _stack.pop_back()
		var x: int = p % _w
		var y: int = p / _w
		var c := img.get_pixel(x, y)
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
		_try_push(x + 1, y, img)
		_try_push(x - 1, y, img)
		_try_push(x, y + 1, img)
		_try_push(x, y - 1, img)


func _key_green(img: Image) -> void:
	## Chroma key with a soft edge: fully green pixels vanish, and the
	## anti-aliased rim is faded out while its green cast is pulled down so the
	## silhouette doesn't keep a green fringe.
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.02:
				continue
			var d := c.g - maxf(c.r, c.b)
			if d >= 0.25:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
			elif d > 0.06:
				var t := (d - 0.06) / 0.19
				var cap := maxf(c.r, c.b)
				img.set_pixel(x, y, Color(c.r, minf(c.g, cap), c.b, c.a * (1.0 - t)))


func _trim(img: Image, pad: int) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var minx := w
	var miny := h
	var maxx := -1
	var maxy := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.02:
				minx = mini(minx, x)
				miny = mini(miny, y)
				maxx = maxi(maxx, x)
				maxy = maxi(maxy, y)
	if maxx < 0:
		return img
	minx = maxi(0, minx - pad)
	miny = maxi(0, miny - pad)
	maxx = mini(w - 1, maxx + pad)
	maxy = mini(h - 1, maxy + pad)
	return img.get_region(Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1))


func _fade_bottom(img: Image, frac: float) -> Image:
	## Softly dissolve the bottom of a bust sprite so a mid-body cut doesn't
	## leave a hard horizontal edge sitting over the background.
	var out := _duplicate_image(img)
	var w := out.get_width()
	var h := out.get_height()
	var start := int(float(h) * (1.0 - clampf(frac, 0.0, 0.9)))
	for y in range(start, h):
		var t := float(y - start) / float(maxi(1, h - 1 - start))
		var mul := 1.0 - t * t
		for x in w:
			var c := out.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			out.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * mul))
	return out
