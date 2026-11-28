extends Node2D
## Builds a land from the text chunks: draws the ground and blocks, and adds collision.

const Data := preload("res://scripts/data.gd")
const T := Data.T
const ROWS := Data.ROWS
const OL := Color("1b1430")

var grid: Array = []          # grid[col][row] -> char
var objs: Array = []          # spawn markers: {t, pos, col, row}
var width_px := 0.0
var theme := {}
var theme_name := "garden"
const THEMES := {
	garden=["8a5a34", "6e4526", "5cc35a", "3f9a45", "a39a8e"],
	desert=["c98f4a", "a9733a", "f2cf86", "d9ad60", "c09a6a"],
	sea=["7d5c3c", "5e432a", "b89466", "94744c", "7a7a86"],
	forest=["4a3a3a", "3a2a2a", "2f7a4a", "1f5236", "5a6a7a"],
	city=["55556a", "3f3f52", "9b9bb0", "77778c", "8a8aa0"],
	snow=["6a7a96", "56647e", "f4f8ff", "cfdcef", "a8b4c8"],
	mount=["43354f", "30253c", "d9c690", "b29f6c", "6d5f80"],
}

func build(level: Dictionary) -> void:
	theme_name = level.theme
	var tc: Array = THEMES.get(theme_name, THEMES.garden)
	theme = {ground=Color(tc[0]), ground2=Color(tc[1]), top=Color(tc[2]), top2=Color(tc[3]), stone=Color(tc[4])}
	var cols: Array = []
	var x0 := 0
	for name in level.chunks:
		var ch: Array = Data.C[name]
		var w := 0
		for r in ch:
			w = maxi(w, r.length())
		var rows: Array = []
		for i in (ROWS - 1 - ch.size()):
			rows.append("")
		rows.append_array(ch)
		rows.append(ch[ch.size() - 1])   # extra floor row keeps pits open
		for c in w:
			var colv: Array = []
			for r in ROWS:
				var s: String = rows[r]
				var t := s[c] if c < s.length() else "."
				if "PoGhsejfcnmtbWB".contains(t):
					objs.append({t=t, pos=Vector2((x0 + c) * T, r * T), col=x0 + c, row=r})
					t = "."
				colv.append(t)
			cols.append(colv)
		x0 += w
	grid = cols
	width_px = cols.size() * T
	_collision()
	queue_redraw()

func tile(c: int, r: int) -> String:
	if c < 0:
		return "#"
	if c >= grid.size() or r < 0 or r >= ROWS:
		return "."
	return grid[c][r]

func solid(c: int, r: int) -> bool:
	return "#X=?!".contains(tile(c, r))

func ground_below(x: float, y: float) -> float:
	var c := int(x / T)
	var r := int(y / T)
	while r < ROWS and not solid(c, r):
		r += 1
	return r * T

func _collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	# merge vertical runs of solid tiles per column into one box each
	for c in grid.size():
		var r := 0
		while r < ROWS:
			if solid(c, r):
				var r0 := r
				while r < ROWS and solid(c, r):
					r += 1
				var sh := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(T, (r - r0) * T)
				sh.shape = rect
				sh.position = Vector2(c * T + T / 2, (r0 + r) * T / 2)
				body.add_child(sh)
			elif tile(c, r) == "-":
				var sh2 := CollisionShape2D.new()
				var rect2 := RectangleShape2D.new()
				rect2.size = Vector2(T, 14)
				sh2.shape = rect2
				sh2.one_way_collision = true
				sh2.position = Vector2(c * T + T / 2, r * T + 7)
				body.add_child(sh2)
				r += 1
			else:
				r += 1

static func hsh(a: float, b := 0.0) -> float:
	var x := sin(a * 127.1 + b * 311.7) * 43758.5453
	return x - floor(x)

func _draw() -> void:
	for c in grid.size():
		for r in ROWS:
			var t: String = grid[c][r]
			if t == ".":
				continue
			var x := c * T
			var y := r * T
			match t:
				"#": _ground(c, r, x, y)
				"X": _stone(x, y)
				"-": _cloud(x, y)
				"^": _thorns(x, y)
				"=": _brick(x, y)
				"?", "!": _crate(x, y, t == "!")

func _ground(c: int, r: int, x: float, y: float) -> void:
	var depth := 0
	var k := r - 1
	while k >= 0 and tile(c, k) == "#":
		depth += 1
		k -= 1
	var g1: Color = theme.ground.darkened(minf(0.5, depth * 0.11))
	var g2: Color = theme.ground.darkened(minf(0.55, (depth + 1) * 0.11))
	draw_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + T + 1, y), Vector2(x + T + 1, y + T + 1), Vector2(x, y + T + 1)]),
		PackedColorArray([g1, g1, g2, g2]))
	for i in 3:
		if hsh(c + i * 7, r) > 0.45:
			var p := Vector2(x + 6 + hsh(c, r + i) * 34, y + 8 + hsh(c + 3, r + i) * 30)
			draw_circle(p, 3.0 + hsh(c + i, r) * 2.0, theme.ground2.darkened(depth * 0.08))
			draw_circle(p - Vector2(1, 1), 1.4, Color(1, 1, 1, 0.08))
	var top := tile(c, r - 1) != "#" and not solid(c, r - 1)
	if top:
		var left_open := tile(c - 1, r) != "#"
		var right_open := tile(c + 1, r) != "#"
		# grass cap with a soft lip hanging over the dirt
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x1 := x - (6.0 if left_open else 0.0)
		var x2 := x + T + (6.0 if right_open else 0.0) + 1
		pts.append(Vector2(x1, y - 3))
		pts.append(Vector2(x2, y - 3))
		var n := 6
		for i in range(n, -1, -1):
			var px := lerpf(x1, x2, float(i) / n)
			pts.append(Vector2(px, y + 14 + sin(px * 0.21) * 3.0))
		cols.append(theme.top.lightened(0.15))
		cols.append(theme.top.lightened(0.15))
		for i in n + 1:
			cols.append(theme.top2)
		draw_polygon(pts, cols)
		draw_line(Vector2(x1, y - 3), Vector2(x2, y - 3), OL, 2.5, false)
		draw_line(Vector2(x1, y - 1), Vector2(x2, y - 1), Color(1, 1, 1, 0.35), 2.0, false)
		if not theme_name in ["garden", "forest", "sea"]:
			return
		# grass blades and little flowers
		for i in 4:
			var bx := x + 5 + i * 11 + hsh(c, i) * 4
			draw_line(Vector2(bx, y - 2), Vector2(bx - 2, y - 9 - hsh(c, i + 9) * 5), theme.top2, 2.0, false)
			draw_line(Vector2(bx + 3, y - 2), Vector2(bx + 5, y - 8), theme.top, 2.0, false)
		if hsh(c, 1) > 0.55:
			var fx := x + 10 + hsh(c, 2) * 26
			var fc: Color = [Color("ff6fa8"), Color("ffd25a"), Color.WHITE, Color("9b5bff")][int(hsh(c, 3) * 4)]
			draw_line(Vector2(fx, y - 2), Vector2(fx, y - 14), Color("3f9a45"), 2.0, false)
			for j in 5:
				draw_circle(Vector2(fx, y - 15) + Vector2.from_angle(j * TAU / 5) * 3.0, 2.4, fc)
			draw_circle(Vector2(fx, y - 15), 1.8, Color("ffe04a"))

func _stone(x: float, y: float) -> void:
	var s: Color = theme.stone
	_rr(Rect2(x + 1, y + 1, T - 2, T - 2), 6, s.darkened(0.25))
	_rr(Rect2(x + 3, y + 3, T - 6, T - 8), 5, s)
	draw_rect(Rect2(x + 6, y + 5, T - 12, 4), Color(1, 1, 1, 0.28))
	draw_line(Vector2(x + 14, y + 18), Vector2(x + 26, y + 25), Color(0, 0, 0, 0.18), 2, false)
	draw_line(Vector2(x + 26, y + 25), Vector2(x + 30, y + 34), Color(0, 0, 0, 0.14), 2, false)

func _brick(x: float, y: float) -> void:
	draw_rect(Rect2(x, y, T, T), Color("a84e28"))
	var m := Color("6e2f14")
	draw_rect(Rect2(x + 1, y + 1, T - 2, T - 2), m, false, 2.0)
	draw_line(Vector2(x, y + T / 2), Vector2(x + T, y + T / 2), m, 2, false)
	draw_line(Vector2(x + T / 2, y), Vector2(x + T / 2, y + T / 2), m, 2, false)
	draw_line(Vector2(x + T / 4, y + T / 2), Vector2(x + T / 4, y + T), m, 2, false)
	draw_line(Vector2(x + T * 0.75, y + T / 2), Vector2(x + T * 0.75, y + T), m, 2, false)
	draw_rect(Rect2(x + 3, y + 3, T - 6, 3), Color(1, 0.75, 0.6, 0.35))

func _crate(x: float, y: float, heart: bool) -> void:
	var g := preload("res://scripts/part.gd").glow_tex()
	draw_texture_rect(g, Rect2(x - 20, y - 20, T + 40, T + 40), false, Color(1, 0.85, 0.45, 0.35))
	_rr(Rect2(x + 1, y + 1, T - 2, T - 2), 5, OL)
	draw_rect(Rect2(x + 4, y + 4, T - 8, T - 8), Color("c98a4a"))
	draw_rect(Rect2(x + 4, y + 4, T - 8, 6), Color("e0b060"))
	draw_rect(Rect2(x + 4, y + T - 10, T - 8, 6), Color("a8703a"))
	draw_line(Vector2(x + 8, y + 10), Vector2(x + T - 8, y + T - 10), Color("8a5a2a"), 5, false)
	for p in [Vector2(x + 8, y + 8), Vector2(x + T - 8, y + 8), Vector2(x + 8, y + T - 8), Vector2(x + T - 8, y + T - 8)]:
		draw_circle(p, 2.2, Color("5a3a1a"))
	var c := Vector2(x + T / 2, y + T / 2)
	draw_circle(c, 12, Color(0.1, 0.06, 0.02, 0.35))
	if heart:
		var hp := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24
			hp.append(c + Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a))) * 0.55)
		draw_colored_polygon(hp, Color("ff4b6a"))
	else:
		draw_rect(Rect2(c.x - 3, c.y - 10, 6, 20), Color("ffe9a8"))
		draw_rect(Rect2(c.x - 8, c.y - 5, 16, 6), Color("ffe9a8"))

func _cloud(x: float, y: float) -> void:
	var w := Color(1, 1, 1, 0.95)
	draw_circle(Vector2(x + 12, y + 10), 12, w)
	draw_circle(Vector2(x + 30, y + 7), 15, w)
	draw_circle(Vector2(x + 45, y + 11), 11, w)
	draw_rect(Rect2(x, y + 9, T, 9), w)
	draw_rect(Rect2(x, y + 15, T, 4), Color(0.6, 0.72, 0.88, 0.7))

func _thorns(x: float, y: float) -> void:
	var g := Color("2f5a2a")
	for i in 4:
		draw_colored_polygon(PackedVector2Array([Vector2(x + i * 12, y + T), Vector2(x + i * 12 + 6, y + 14), Vector2(x + i * 12 + 12, y + T)]), Color("3d6a2a"))
	draw_arc(Vector2(x + T / 2, y + T), 26, PI * 1.15, PI * 1.85, 10, g, 4, false)
	draw_circle(Vector2(x + 10, y + 27), 4, Color("d8343a"))
	draw_circle(Vector2(x + 36, y + 24), 4, Color("d8343a"))

func _rr(r: Rect2, rad: float, c: Color) -> void:
	draw_rect(Rect2(r.position + Vector2(rad, 0), r.size - Vector2(rad * 2, 0)), c)
	draw_rect(Rect2(r.position + Vector2(0, rad), r.size - Vector2(0, rad * 2)), c)
	for p in [r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.position.x + rad, r.end.y - rad), r.end - Vector2(rad, rad)]:
		draw_circle(p, rad, c)
