extends RefCounted
## Backgrounds for every land: sky, sun or moon, layered scenery that slides at different
## speeds (parallax), weather particles and foreground silhouettes.

const Part := preload("res://scripts/part.gd")
const Fx := preload("res://scripts/fx.gd")
const OL := Color("1b1430")

const SKIES := {
	garden={top="4aa6f0", bot="e2f5ff", sun="fff7d6", sun_x=0.2, sun_y=130, rays=true, stars=0},
	desert={top="f59a5a", bot="ffe2b0", sun="fff0c0", sun_x=0.75, sun_y=170, rays=true, stars=0},
	sea={top="1f3350", bot="7a92ae", sun="", stars=0, storm=true},
	forest={top="0a1030", bot="2c3f63", moon=true, sun_x=0.78, sun_y=120, stars=90},
	city={top="3d3d8a", bot="ffb07a", sun="ffcf90", sun_x=0.5, sun_y=520, stars=25},
	snow={top="8ec5f0", bot="eef7ff", sun="ffffff", sun_x=0.3, sun_y=110, rays=true, stars=0},
	mount={top="170b26", bot="b4464a", sun="ffcfa8", sun_x=0.78, sun_y=160, stars=60},
}

static func build(main: Node2D, level_w: float, theme: String) -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	main.add_child(sky_layer)
	var sky := SkyArt.new()
	sky.cfg = SKIES.get(theme, SKIES.garden)
	sky_layer.add_child(sky)
	match theme:
		"garden":
			_para(main, 0.06, -14.0, 2600, func(): return Clouds.make(Color.WHITE, 1.0), -9, level_w)
			_para(main, 0.18, 0.0, 2048, func(): return Land.make("hill", 455, 46, 3, Color("9ad8a0"), "trees", 11), -8, level_w)
			_para(main, 0.38, 0.0, 2048, func(): return Land.make("hill", 545, 40, 4, Color("62b45c"), "trees+mill", 23), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("1f4a26")), 20, level_w)
		"desert":
			_para(main, 0.05, -10.0, 2600, func(): return Clouds.make(Color(1, 0.95, 0.9), 0.6), -9, level_w)
			_para(main, 0.15, 0.0, 2048, func(): return Land.make("mesa", 470, 70, 3, Color("e7a96a"), "", 5), -8, level_w)
			_para(main, 0.32, 0.0, 2048, func(): return Land.make("dune", 540, 30, 4, Color("f0c07c"), "cactus", 7), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("8a5a2a")), 20, level_w)
		"sea":
			_para(main, 0.05, -40.0, 2600, func(): return Clouds.make(Color("4a5a78"), 1.4), -9, level_w)
			_para(main, 0.15, 0.0, 2048, func(): return Land.make("water", 500, 10, 6, Color("2f5a86"), "lighthouse", 3), -8, level_w)
			_para(main, 0.35, 0.0, 2048, func(): return Land.make("water", 560, 14, 8, Color("1d4470"), "boats", 9), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("13263e")), 20, level_w)
		"forest":
			_para(main, 0.12, 0.0, 2048, func(): return Land.make("pines", 470, 30, 3, Color("1c3352"), "", 13), -8, level_w)
			_para(main, 0.3, 0.0, 2048, func(): return Land.make("pines", 540, 26, 4, Color("142640"), "", 17), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("070d1a")), 20, level_w)
		"city":
			_para(main, 0.12, 0.0, 2048, func(): return Land.make("city", 560, 0, 0, Color("5a5a9a"), "", 3), -8, level_w)
			_para(main, 0.3, 0.0, 2048, func(): return Land.make("city", 610, 0, 0, Color("3a3a6a"), "", 9), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("1a1830")), 20, level_w)
		"snow":
			_para(main, 0.06, -10.0, 2600, func(): return Clouds.make(Color.WHITE, 0.8), -9, level_w)
			_para(main, 0.14, 0.0, 2048, func(): return Land.make("peaks", 470, 150, 4, Color("9ab0d0"), "", 4), -8, level_w)
			_para(main, 0.32, 0.0, 2048, func(): return Land.make("hill", 560, 40, 4, Color("e8f0fa"), "snowpines", 21), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("c8d6ea")), 20, level_w)
		"mount":
			_para(main, 0.12, 0.0, 2048, func(): return Land.make("peaks", 440, 160, 3, Color("3a2550"), "church", 6), -8, level_w)
			_para(main, 0.32, 0.0, 2048, func(): return Land.make("peaks", 540, 90, 5, Color("281a3a"), "", 8), -7, level_w)
			_para(main, 1.22, 0.0, 1800, func(): return Bushes.make(Color("120a1c")), 20, level_w)

## Weather and floating bits that travel with the camera.
static func particles(camera: Node2D, theme: String) -> void:
	match theme:
		"garden":
			_pp(camera, 46, 9.0, Vector2(900, 420), Vector2(-1, -0.3), 8, 26, Vector2(0, -4), Color(1, 0.96, 0.75), 0.04, 0.1, true)
			_pp(camera, 16, 12.0, Vector2(900, 10), Vector2(-1, 0.4), 30, 60, Vector2(0, 14), Color(1, 0.62, 0.78), 0.07, 0.11, false, Vector2(0, -420))
		"desert":
			_pp(camera, 70, 3.0, Vector2(900, 380), Vector2(-1, 0.05), 300, 520, Vector2.ZERO, Color(1, 0.85, 0.6, 0.7), 0.03, 0.06, false)
		"sea":
			_pp(camera, 220, 1.2, Vector2(900, 10), Vector2(-0.25, 1), 900, 1200, Vector2.ZERO, Color(0.75, 0.85, 1, 0.55), 0.02, 0.035, false, Vector2(0, -420), Vector2(0.4, 6.0))
		"forest":
			_pp(camera, 40, 7.0, Vector2(900, 380), Vector2(0, -1), 10, 30, Vector2(0, -2), Color(0.85, 1, 0.45), 0.05, 0.1, true)
		"city":
			_pp(camera, 30, 9.0, Vector2(900, 420), Vector2(-1, -0.2), 10, 25, Vector2(0, -3), Color(1, 0.85, 0.6), 0.03, 0.06, true)
		"snow":
			_pp(camera, 140, 7.0, Vector2(900, 10), Vector2(-0.3, 1), 60, 120, Vector2(0, 10), Color(1, 1, 1, 0.9), 0.04, 0.1, false, Vector2(0, -420))
		"mount":
			_pp(camera, 60, 6.0, Vector2(900, 10), Vector2(0.2, -1), 40, 110, Vector2.ZERO, Color(1, 0.55, 0.3), 0.03, 0.07, true, Vector2(0, 420))

static func _pp(parent: Node, n: int, life: float, ext: Vector2, dir: Vector2, v0: float, v1: float, grav: Vector2, col: Color, s0: float, s1: float, add: bool, pos := Vector2.ZERO, stretch := Vector2.ONE) -> void:
	var p := CPUParticles2D.new()
	p.amount = n
	p.lifetime = life
	p.preprocess = life
	p.position = pos
	p.texture = Part.glow_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = ext
	p.direction = dir
	p.spread = 25
	p.initial_velocity_min = v0
	p.initial_velocity_max = v1
	p.gravity = grav
	p.scale_amount_min = s0
	p.scale_amount_max = s1
	if stretch != Vector2.ONE:
		p.particle_flag_align_y = true
		p.scale_amount_min = s0 * stretch.y
		p.scale_amount_max = s1 * stretch.y
	var g := Gradient.new()
	g.set_color(0, Color(col, 0))
	g.add_point(0.25, col)
	g.set_color(1, Color(col, 0))
	p.color_ramp = g
	if add:
		p.material = Fx.additive()
	p.z_index = 9
	parent.add_child(p)

## A background layer that slides slower (or faster) than the camera.
static func _para(main: Node2D, s: float, auto: float, period: float, make: Callable, z: int, level_w: float) -> Node2D:
	var p := Para.new()
	p.factor = s
	p.auto = auto
	p.period = period
	p.z_index = z
	var copies := int(ceil((level_w * absf(s) + 3200.0) / period)) + 2
	for i in copies:
		var n: Node2D = make.call()
		n.position.x = (i - 1) * period
		p.add_child(n)
	main.add_child(p)
	return p

class Para extends Node2D:
	var factor := 0.5
	var auto := 0.0
	var period := 2048.0
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		var left := cam.get_screen_center_position().x
		position.x = left * (1.0 - factor) + fposmod(t * auto, period) - (period if auto != 0.0 else 0.0)

class SkyArt extends Node2D:
	var cfg := {}
	var t := 0.0
	var bolt := 0.0
	func _process(d: float) -> void:
		t += d
		if cfg.get("storm", false):
			bolt = maxf(0.0, bolt - d * 3.0)
			if randf() < d * 0.25:
				bolt = 1.0
		queue_redraw()
	func _draw() -> void:
		var s := get_viewport_rect().size
		var top := Color(String(cfg.top))
		var bot := Color(String(cfg.bot))
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(0, s.y)]), PackedColorArray([top, top, bot, bot]))
		var stars: int = cfg.get("stars", 0)
		for i in stars:
			var x := fmod(i * 97.3, s.x)
			var y := fmod(i * 53.7, s.y * 0.6)
			var tw := 0.5 + 0.5 * sin(t * 2.0 + i)
			draw_circle(Vector2(x, y), 1.2 + tw * 1.2, Color(1, 1, 1, 0.35 + tw * 0.5))
		var g := Part.glow_tex()
		var c := Vector2(s.x * float(cfg.get("sun_x", 0.2)), float(cfg.get("sun_y", 130)))
		if cfg.get("moon", false):
			draw_texture_rect(g, Rect2(c - Vector2(160, 160), Vector2(320, 320)), false, Color(0.8, 0.85, 1, 0.35))
			draw_circle(c, 44, Color("eef0ff"))
			draw_circle(c + Vector2(-12, -8), 8, Color("d0d4e8"))
			draw_circle(c + Vector2(14, 12), 6, Color("d0d4e8"))
		elif String(cfg.get("sun", "")) != "":
			var sc := Color(String(cfg.sun))
			if cfg.get("rays", false):
				for i in 9:
					var a := i * TAU / 9 + t * 0.03
					draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.07) * 1500, c + Vector2.from_angle(a + 0.07) * 1500]), Color(1, 0.97, 0.85, 0.06 + 0.02 * sin(t * 0.7 + i)))
			draw_texture_rect(g, Rect2(c - Vector2(260, 260), Vector2(520, 520)), false, Color(sc, 0.75))
			draw_circle(c, 46, sc)
			draw_circle(c, 38, sc.lightened(0.4))
		draw_polygon(PackedVector2Array([Vector2(0, s.y * 0.45), Vector2(s.x, s.y * 0.45), Vector2(s.x, s.y), Vector2(0, s.y)]),
			PackedColorArray([Color(bot, 0), Color(bot, 0), Color(bot.lightened(0.15), 0.35), Color(bot.lightened(0.15), 0.35)]))
		if bolt > 0.0:
			draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.35 * bolt))
			var x0 := s.x * 0.65
			var pts := PackedVector2Array([Vector2(x0, 0)])
			for i in 6:
				pts.append(Vector2(x0 + sin(i * 7.1) * 40, (i + 1) * 60))
			draw_polyline(pts, Color(1, 1, 1, bolt), 4, false)

class Clouds extends Node2D:
	var col := Color.WHITE
	var k0 := 1.0
	static func make(c: Color, k: float) -> Clouds:
		var n := Clouds.new()
		n.col = c
		n.k0 = k
		return n
	func _draw() -> void:
		for c in [[120, 90, 1.3], [520, 150, 0.9], [860, 70, 1.6], [1300, 130, 1.1], [1750, 80, 1.4], [2200, 160, 1.0]]:
			var x: float = c[0]
			var y: float = c[1]
			var k: float = c[2] * k0
			for b in [[0, 0, 34], [40, -18, 44], [86, 0, 34], [44, 10, 38]]:
				draw_circle(Vector2(x + b[0] * k, y + b[1] * k + 6), b[2] * k, col.darkened(0.18))
			for b in [[0, 0, 34], [40, -18, 44], [86, 0, 34], [44, 10, 38]]:
				draw_circle(Vector2(x + b[0] * k, y + b[1] * k), b[2] * k * 0.94, col)
			draw_circle(Vector2(x + 30 * k, y - 26 * k), 14 * k, col.lightened(0.1))

## One band of scenery: rolling hills, dunes, mesas, peaks, pines, water or city blocks.
class Land extends Node2D:
	var style := "hill"
	var base := 500.0
	var amp := 40.0
	var waves := 3
	var col := Color.GREEN
	var props := ""
	var seed := 1
	var period := 2048.0
	var t := 0.0
	static func make(st: String, b: float, a: float, w: int, c: Color, p: String, sd: int) -> Land:
		var l := Land.new()
		l.style = st
		l.base = b
		l.amp = a
		l.waves = w
		l.col = c
		l.props = p
		l.seed = sd
		return l
	func _h(i: int) -> float:
		var v := sin(i * 127.1 + seed * 311.7) * 43758.5453
		return v - floor(v)
	func y_at(x: float) -> float:
		var f := TAU * waves / period
		match style:
			"dune": return base - sin(x * f) * amp - sin(x * f * 2.0 + 1.0) * amp * 0.3
			"mesa":
				var v := sin(x * f) * 0.5 + 0.5
				return base - (amp if v > 0.55 else amp * 0.15) - sin(x * f * 5.0) * 4.0
			"peaks":
				var tri := absf(fposmod(x * waves / period * 2.0, 2.0) - 1.0)
				return base - (1.0 - tri) * amp - sin(x * f * 3.0) * amp * 0.12
			"water": return base - sin(x * f + t * 1.5) * amp
			_: return base - sin(x * f) * amp - amp * 0.4 * sin(x * f * 2.0 + 1.3)
	func _ready() -> void:
		if props.contains("mill"):
			var m := Windmill.new()
			m.position = Vector2(620, y_at(620) + 4)
			add_child(m)
			var cot := Cottage.new()
			cot.position = Vector2(1560, y_at(1560) + 4)
			add_child(cot)
	func _process(d: float) -> void:
		if style == "water" or props == "boats" or props == "lighthouse":
			t += d
			queue_redraw()
	func _draw() -> void:
		if style == "city":
			_city()
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var x := 0.0
		var step := 8.0 if style == "peaks" else 16.0
		while x <= period + 0.1:
			pts.append(Vector2(x, y_at(x)))
			cols.append(col.lightened(0.06))
			x += step
		pts.append(Vector2(period, 760))
		cols.append(col.darkened(0.35))
		pts.append(Vector2(0, 760))
		cols.append(col.darkened(0.35))
		draw_polygon(pts, cols)
		var rim := PackedVector2Array()
		for i in range(pts.size() - 2):
			rim.append(pts[i] + Vector2(0, 2))
		draw_polyline(rim, col.lightened(0.28), 3.0, false)
		if style == "peaks":
			_snowcaps()
		if style == "water":
			for row in 3:
				var w := PackedVector2Array()
				x = 0.0
				while x <= period:
					w.append(Vector2(x, y_at(x) + 26 + row * 34 + sin(x * 0.03 + t * 2.0 + row) * 4))
					x += 24.0
				draw_polyline(w, Color(1, 1, 1, 0.18 - row * 0.04), 2, false)
		var i := 0
		x = 40.0
		while x < period - 40:
			var h := _h(i)
			var p := Vector2(x, y_at(x) + 6)
			if props.contains("trees") and h > 0.45 and absf(x - 620) > 90 and absf(x - 1560) > 90:
				_tree(p, (0.55 if base < 500 else 0.9) * (0.8 + h * 0.5))
			elif props == "cactus" and h > 0.7:
				_cactus(p, 0.8 + h * 0.4)
			elif props == "snowpines" and h > 0.5:
				_pine(p, 0.8 + h * 0.5, Color("2f5a4a"), true)
			elif style == "pines" and h > 0.2:
				_pine(p, (0.7 if base < 500 else 1.0) * (0.8 + h * 0.6), col.darkened(0.25), false)
			x += (34.0 if style == "pines" else 70.0) + h * 50.0
			i += 1
		if props == "lighthouse":
			_lighthouse(Vector2(1300, y_at(1300) + 10))
		if props == "boats":
			for bx in [400.0, 1400.0]:
				_boat(Vector2(bx, y_at(bx) + 4))
		if props == "church":
			_church(Vector2(1000, y_at(1000) + 4))
	func _snowcaps() -> void:
		if col.v > 0.5:
			var x := 0.0
			while x < period:
				var y := y_at(x)
				if y < base - amp * 0.6:
					draw_circle(Vector2(x, y + 10), 14, Color(1, 1, 1, 0.85))
				x += 12.0
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
	func _pine(p: Vector2, s: float, c: Color, snow: bool) -> void:
		draw_line(p, p + Vector2(0, -16 * s), Color("4a3020"), 6 * s, false)
		for k in 3:
			var y := -14 * s - k * 18 * s
			var w := (30 - k * 8) * s
			draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y), p + Vector2(0, y - 34 * s), p + Vector2(w, y)]), c.lightened(k * 0.05))
			if snow:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-w * 0.5, y - 17 * s), p + Vector2(0, y - 34 * s), p + Vector2(w * 0.5, y - 17 * s)]), Color(1, 1, 1, 0.9))
	func _cactus(p: Vector2, s: float) -> void:
		var c := Color("4f8a3f")
		draw_line(p + Vector2(0, 6), p + Vector2(0, -44 * s), c, 11 * s, false)
		draw_line(p + Vector2(0, -20 * s), p + Vector2(-14 * s, -20 * s), c, 8 * s, false)
		draw_line(p + Vector2(-14 * s, -20 * s), p + Vector2(-14 * s, -34 * s), c, 8 * s, false)
		draw_line(p + Vector2(0, -28 * s), p + Vector2(14 * s, -28 * s), c, 8 * s, false)
		draw_line(p + Vector2(14 * s, -28 * s), p + Vector2(14 * s, -42 * s), c, 8 * s, false)
		draw_line(p + Vector2(-2 * s, -40 * s), p + Vector2(-2 * s, 0), c.lightened(0.2), 3 * s, false)
	func _lighthouse(p: Vector2) -> void:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0), p + Vector2(-11, -140), p + Vector2(11, -140), p + Vector2(16, 0)]), Color("e8e0d0"))
		for y in [-40, -90]:
			draw_rect(Rect2(p + Vector2(-14, y), Vector2(28, 14)), Color("d8343a"))
		draw_rect(Rect2(p + Vector2(-16, -160), Vector2(32, 20)), Color("333344"))
		var a := t * 1.2
		var c := p + Vector2(0, -150)
		draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.1) * 500, c + Vector2.from_angle(a + 0.1) * 500]), Color(1, 0.95, 0.6, 0.18))
		draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(40, 40), Vector2(80, 80)), false, Color(1, 0.95, 0.6, 0.9))
	func _boat(p: Vector2) -> void:
		var rock := sin(t * 1.5 + p.x) * 0.06
		draw_set_transform(p, rock, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-40, 0), Vector2(40, 0), Vector2(28, 16), Vector2(-28, 16)]), Color("8a5a32"))
		draw_line(Vector2(0, 0), Vector2(0, -64), Color("5a3a22"), 3)
		draw_colored_polygon(PackedVector2Array([Vector2(3, -62), Vector2(36, -8), Vector2(3, -8)]), Color("f4f0e6"))
		draw_set_transform(Vector2.ZERO)
	func _church(p: Vector2) -> void:
		var c := Color("1a0f28")
		draw_rect(Rect2(p + Vector2(-60, -70), Vector2(120, 70)), c)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-70, -68), p + Vector2(0, -120), p + Vector2(70, -68)]), c)
		draw_rect(Rect2(p + Vector2(-14, -170), Vector2(28, 60)), c)
		draw_rect(Rect2(p + Vector2(-3, -210), Vector2(6, 40)), c)
		draw_rect(Rect2(p + Vector2(-12, -200), Vector2(24, 6)), c)
		draw_texture_rect(Part.glow_tex(), Rect2(p + Vector2(-110, -180), Vector2(220, 200)), false, Color(1, 0.75, 0.45, 0.25))
		draw_rect(Rect2(p + Vector2(-12, -40), Vector2(24, 40)), Color("3a1a2a"))
	func _city() -> void:
		var x := 0.0
		var i := 0
		while x < period:
			var h := 120.0 + _h(i) * 220.0
			var w := 80.0 + _h(i + 50) * 40.0
			draw_rect(Rect2(x, base - h, w, 800), col)
			draw_rect(Rect2(x, base - h, 6, 800), col.lightened(0.1))
			if _h(i + 7) > 0.6:
				draw_rect(Rect2(x + w * 0.4, base - h - 30, 6, 30), col)
			var yy := base - h + 16
			while yy < base - 10:
				var xx := x + 12.0
				while xx < x + w - 14:
					if _h(int(xx * 3 + yy)) > 0.55:
						draw_rect(Rect2(xx, yy, 10, 14), Color(1, 0.84, 0.43, 0.75))
					xx += 20.0
				yy += 26.0
			x += w + 6.0
			i += 1

class Windmill extends Node2D:
	var blades: Node2D
	func _ready() -> void:
		blades = Blades.new()
		blades.position = Vector2(0, -92)
		add_child(blades)
	func _process(d: float) -> void:
		blades.rotation += d * 0.6
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(14, -92), Vector2(24, 0)]), Color("efe2c8"))
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(-4, -92), Vector2(-8, 0)]), Color(0, 0, 0, 0.08))
		draw_polyline(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -92), Vector2(14, -92), Vector2(24, 0)]), OL, 2, false)
		draw_colored_polygon(PackedVector2Array([Vector2(-18, -92), Vector2(0, -114), Vector2(18, -92)]), Color("b4552a"))
		draw_rect(Rect2(-6, -24, 12, 24), Color("7a4a2a"))
		draw_circle(Vector2(0, -60), 6, Color("8fc8f0"))

class Blades extends Node2D:
	func _draw() -> void:
		for i in 4:
			var dir := Vector2.from_angle(i * PI / 2)
			var side := dir.orthogonal()
			draw_colored_polygon(PackedVector2Array([dir * 6 + side * 2, dir * 58 + side * 2, dir * 58 + side * 11, dir * 6 + side * 8]), Color("e4d2b0"))
			draw_line(dir * 6, dir * 58, Color("6a4a2a"), 3, false)
		draw_circle(Vector2.ZERO, 6, OL)

class Cottage extends Node2D:
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-36, -40, 72, 40), Color("f3e4c6"))
		draw_rect(Rect2(-36, -40, 72, 40), OL, false, 2)
		draw_colored_polygon(PackedVector2Array([Vector2(-44, -38), Vector2(0, -72), Vector2(44, -38)]), Color("b4552a"))
		draw_rect(Rect2(16, -76, 10, 20), Color("8a5a3a"))
		for i in 3:
			var k := fmod(t * 0.4 + i / 3.0, 1.0)
			draw_circle(Vector2(21 + sin(t + i) * 4, -82 - k * 40), 5 + k * 6, Color(0.92, 0.92, 0.95, 0.4 * (1 - k)))
		for wx in [-24, 8]:
			draw_rect(Rect2(wx, -30, 16, 14), Color("9cc8ea"))
		draw_rect(Rect2(-6, -22, 12, 22), Color("7a4a2a"))

class Bushes extends Node2D:
	var col := Color("1f4a26")
	static func make(c: Color) -> Bushes:
		var b := Bushes.new()
		b.col = c
		return b
	func _draw() -> void:
		for b in [[80, 1.0], [420, 1.4], [700, 0.9], [1080, 1.2], [1420, 1.0], [1660, 1.3]]:
			var x: float = b[0]
			var k: float = b[1]
			for c in [[0, 0, 40], [44, -16, 50], [92, 4, 38]]:
				draw_circle(Vector2(x + c[0] * k, 742 + c[1] * k), c[2] * k, col)
			draw_circle(Vector2(x + 36 * k, 708 - 4 * k), 12 * k, col.lightened(0.12))
