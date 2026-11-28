extends RefCounted
## Garden of Hope backdrop: sky, sun rays, clouds, layered hills, windmill and foreground bushes.

const Part := preload("res://scripts/part.gd")
const OL := Color("1b1430")

static func build(main: Node2D, level_w: float) -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	main.add_child(sky_layer)
	sky_layer.add_child(SkyArt.new())
	_parallax(main, 0.06, Vector2(-14, 0), 2600, Clouds.new(), -9)
	_parallax(main, 0.18, Vector2.ZERO, 2048, Hills.make(455, 46, 3, Color("9ad8a0"), 0.55, 11, false), -8)
	_parallax(main, 0.38, Vector2.ZERO, 2048, Hills.make(545, 40, 4, Color("62b45c"), 0.9, 23, true), -7)
	var fg := _parallax(main, 1.22, Vector2.ZERO, 1800, Bushes.new(), 20)
	fg.modulate = Color(1, 1, 1, 0.96)

static func _parallax(main: Node2D, s: float, auto: Vector2, period: float, child: Node2D, z: int) -> Parallax2D:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(s, 1)
	p.repeat_size = Vector2(period, 0)
	p.repeat_times = 4
	p.autoscroll = auto
	p.z_index = z
	p.add_child(child)
	main.add_child(p)
	return p

static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float) -> void:
	ci.draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false, Color(col, a))

class SkyArt extends Node2D:
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var s := get_viewport_rect().size
		var top := Color("4aa6f0")
		var bot := Color("e2f5ff")
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(0, s.y)]), PackedColorArray([top, top, bot, bot]))
		var sun := Vector2(s.x * 0.2, 130)
		# sun rays slowly turning
		for i in 9:
			var a := i * TAU / 9 + t * 0.03
			var p1 := sun + Vector2.from_angle(a - 0.07) * 1400
			var p2 := sun + Vector2.from_angle(a + 0.07) * 1400
			draw_colored_polygon(PackedVector2Array([sun, p1, p2]), Color(1, 0.97, 0.85, 0.06 + 0.02 * sin(t * 0.7 + i)))
		draw_texture_rect(Part.glow_tex(), Rect2(sun - Vector2(260, 260), Vector2(520, 520)), false, Color(Color("fff2c0"), 0.75))
		draw_circle(sun, 46, Color("fff7d6"))
		draw_circle(sun, 40, Color("fffbe8"))
		# haze near the horizon
		draw_polygon(PackedVector2Array([Vector2(0, s.y * 0.45), Vector2(s.x, s.y * 0.45), Vector2(s.x, s.y), Vector2(0, s.y)]),
			PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 0.98, 0.9, 0.35), Color(1, 0.98, 0.9, 0.35)]))

class Clouds extends Node2D:
	func _draw() -> void:
		var spots := [[120, 90, 1.3], [520, 150, 0.9], [860, 70, 1.6], [1300, 130, 1.1], [1750, 80, 1.4], [2200, 160, 1.0]]
		for c in spots:
			var x: float = c[0]
			var y: float = c[1]
			var k: float = c[2]
			for b in [[0, 0, 34], [40, -18, 44], [86, 0, 34], [44, 10, 38]]:
				draw_circle(Vector2(x + b[0] * k, y + b[1] * k + 6), b[2] * k, Color(0.78, 0.86, 0.95, 0.9))
			for b in [[0, 0, 34], [40, -18, 44], [86, 0, 34], [44, 10, 38]]:
				draw_circle(Vector2(x + b[0] * k, y + b[1] * k), b[2] * k * 0.94, Color(1, 1, 1, 0.97))
			draw_circle(Vector2(x + 30 * k, y - 26 * k), 14 * k, Color(1, 1, 1, 1))

class Hills extends Node2D:
	var base := 500.0
	var amp := 40.0
	var waves := 3
	var col := Color.GREEN
	var tree_k := 1.0
	var seed := 1
	var props := false
	var period := 2048.0
	var mill: Node2D

	static func make(b: float, a: float, w: int, c: Color, tk: float, sd: int, p: bool) -> Hills:
		var h := Hills.new()
		h.base = b
		h.amp = a
		h.waves = w
		h.col = c
		h.tree_k = tk
		h.seed = sd
		h.props = p
		return h

	func y_at(x: float) -> float:
		var f := TAU * waves / period
		return base - sin(x * f) * amp - amp * 0.4 * sin(x * f * 2.0 + 1.3)

	func _ready() -> void:
		if props:
			mill = Windmill.new()
			mill.position = Vector2(620, y_at(620) + 4)
			add_child(mill)
			var cot := Cottage.new()
			cot.position = Vector2(1560, y_at(1560) + 4)
			add_child(cot)

	func _draw() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := 0.0
		while x <= period + 0.1:
			pts.append(Vector2(x, y_at(x)))
			cols.append(col.lightened(0.06))
			x += 16.0
		pts.append(Vector2(period, 760))
		cols.append(col.darkened(0.32))
		pts.append(Vector2(0, 760))
		cols.append(col.darkened(0.32))
		draw_polygon(pts, cols)
		var rim := PackedVector2Array()
		x = 0.0
		while x <= period + 0.1:
			rim.append(Vector2(x, y_at(x) + 2))
			x += 16.0
		draw_polyline(rim, col.lightened(0.3), 3.0, false)
		# trees at fixed spots so nothing pops while scrolling
		var i := 0
		x = 40.0
		while x < period - 40:
			var h := _h(i)
			if h > 0.45 and absf(x - 620) > 90 and absf(x - 1560) > 90:
				_tree(Vector2(x, y_at(x) + 6), tree_k * (0.8 + h * 0.5))
			x += 70.0 + h * 50.0
			i += 1

	func _h(i: int) -> float:
		var v := sin(i * 127.1 + seed * 311.7) * 43758.5453
		return v - floor(v)

	func _tree(p: Vector2, s: float) -> void:
		var trunk := Color("6a4426")
		draw_line(p, p + Vector2(0, -34 * s), trunk.darkened(0.2), 9 * s, false)
		draw_line(p + Vector2(-1.5 * s, 0), p + Vector2(-1.5 * s, -32 * s), trunk, 5 * s, false)
		var c1 := col.darkened(0.12)
		var c2 := col.darkened(0.28)
		draw_circle(p + Vector2(3 * s, -36 * s), 25 * s, Color(0, 0, 0, 0.12))
		for b in [[0, -40, 22], [-14, -32, 16], [14, -33, 16]]:
			draw_circle(p + Vector2(b[0], b[1]) * s, b[2] * s, c2)
		draw_circle(p + Vector2(-3, -46) * s, 15 * s, c1)
		draw_circle(p + Vector2(-8, -52) * s, 7 * s, col.lightened(0.15))
		draw_circle(p + Vector2(9, -30) * s, 8 * s, Color(0, 0, 0, 0.1))

class Windmill extends Node2D:
	var blades: Node2D
	func _ready() -> void:
		blades = Blades.new()
		blades.position = Vector2(0, -92)
		add_child(blades)
	func _process(d: float) -> void:
		blades.rotation += d * 0.6
	func _draw() -> void:
		var wall := Color("efe2c8")
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(14, -92), Vector2(24, 0)]), wall)
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(-4, -92), Vector2(-8, 0)]), Color(0, 0, 0, 0.08))
		draw_polyline(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(14, -92), Vector2(24, 0)]), OL, 2, false)
		draw_colored_polygon(PackedVector2Array([Vector2(-18, -92), Vector2(0, -114), Vector2(18, -92)]), Color("b4552a"))
		draw_polyline(PackedVector2Array([Vector2(-18, -92), Vector2(0, -114), Vector2(18, -92), Vector2(-18, -92)]), OL, 2, false)
		draw_rect(Rect2(-6, -24, 12, 24), Color("7a4a2a"))
		draw_circle(Vector2(0, -60), 6, Color("8fc8f0"))

class Blades extends Node2D:
	func _draw() -> void:
		for i in 4:
			var a := i * PI / 2
			var dir := Vector2.from_angle(a)
			var side := dir.orthogonal()
			var p0 := dir * 6
			var p1 := dir * 58
			draw_colored_polygon(PackedVector2Array([p0 + side * 2, p1 + side * 2, p1 + side * 11, p0 + side * 8]), Color("e4d2b0"))
			draw_line(p0, p1, Color("6a4a2a"), 3, false)
			for k in 4:
				var q := dir * (16 + k * 11)
				draw_line(q + side * 2, q + side * 10, Color(0.42, 0.29, 0.16, 0.6), 1.5, false)
		draw_circle(Vector2.ZERO, 6, OL)
		draw_circle(Vector2.ZERO, 4, Color("8a6a4a"))

class Cottage extends Node2D:
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-36, -40, 72, 40), Color("f3e4c6"))
		draw_rect(Rect2(-36, -40, 26, 40), Color(0, 0, 0, 0.06))
		draw_rect(Rect2(-36, -40, 72, 40), OL, false, 2)
		draw_colored_polygon(PackedVector2Array([Vector2(-44, -38), Vector2(0, -72), Vector2(44, -38)]), Color("b4552a"))
		draw_polyline(PackedVector2Array([Vector2(-44, -38), Vector2(0, -72), Vector2(44, -38), Vector2(-44, -38)]), OL, 2, false)
		draw_rect(Rect2(16, -76, 10, 20), Color("8a5a3a"))
		for i in 3:
			var k := fmod(t * 0.4 + i / 3.0, 1.0)
			draw_circle(Vector2(21 + sin(t + i) * 4, -82 - k * 40), 5 + k * 6, Color(0.92, 0.92, 0.95, 0.4 * (1 - k)))
		for wx in [-24, 8]:
			draw_rect(Rect2(wx, -30, 16, 14), Color("9cc8ea"))
			draw_rect(Rect2(wx, -30, 16, 14), OL, false, 1.5)
		draw_rect(Rect2(-6, -22, 12, 22), Color("7a4a2a"))

class Bushes extends Node2D:
	func _draw() -> void:
		var dark := Color("1f4a26")
		for b in [[80, 1.0], [420, 1.4], [700, 0.9], [1080, 1.2], [1420, 1.0], [1660, 1.3]]:
			var x: float = b[0]
			var k: float = b[1]
			for c in [[0, 0, 40], [44, -16, 50], [92, 4, 38]]:
				draw_circle(Vector2(x + c[0] * k, 742 + c[1] * k), c[2] * k, dark)
			draw_circle(Vector2(x + 36 * k, 712 * 1.0 - 4 * k), 12 * k, Color("2c6232"))
