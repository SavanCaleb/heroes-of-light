extends Node2D
## One drawable body part of a cartoon character (head, torso, limb, shoe...).
## Shapes are drawn in "web units" (the original game's coordinates) and scaled up,
## so every character keeps the same look as the web version, just smoother.

const OL := Color("1b1430")
const K := 3.0

var kind := ""
var look: Dictionary = {}
var rig = null            # owning rig, for blink / mouth / time
var seg := 0.0            # limb length (web units)
var wid := 0.0            # limb width (web units)
var col := Color.WHITE
var hs := 1.16            # head scale

static var _glow: Texture2D

static func glow_tex() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var tx := GradientTexture2D.new()
		tx.gradient = g
		tx.fill = GradientTexture2D.FILL_RADIAL
		tx.fill_from = Vector2(0.5, 0.5)
		tx.fill_to = Vector2(1.0, 0.5)
		tx.width = 128
		tx.height = 128
		_glow = tx
	return _glow

static func shade(c: Color, a: float) -> Color:
	return c.lightened(a) if a > 0.0 else c.darkened(-a)

func L(key: String, def = null):
	return look.get(key, def)

func C(key: String, def := "#ff00ff") -> Color:
	return Color(String(look.get(key, def)))

# ---------- small drawing helpers ----------
static func arc_pts(c: Vector2, r: float, a0: float, a1: float, n := 14) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		p.append(c + Vector2(cos(a), sin(a)) * r)
	return p

static func ell_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 18) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p

static func quad(p0: Vector2, p1: Vector2, p2: Vector2, n := 8) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(1, n + 1):
		var t := float(i) / n
		p.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return p

func shape(pts: PackedVector2Array, fill: Color, ow := 0.8) -> void:
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, fill)
	if ow > 0.0:
		var q := pts.duplicate()
		q.append(pts[0])
		draw_polyline(q, OL, ow, false)

func cap(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	draw_line(a, b, c, w, false)
	draw_circle(a, w * 0.5, c, true, -1.0, false)
	draw_circle(b, w * 0.5, c, true, -1.0, false)

func circ(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c, maxf(r, 0.01), color, true, -1.0, false)

func ln(a: Vector2, b: Vector2, color: Color, w: float) -> void:
	draw_line(a, b, color, w, false)

func rrect(x: float, y: float, w: float, h: float, r: float, fill: Color, ow := 0.0) -> void:
	r = minf(r, minf(w, h) * 0.5)
	var p := PackedVector2Array()
	p.append_array(arc_pts(Vector2(x + w - r, y + r), r, -PI / 2, 0, 4))
	p.append_array(arc_pts(Vector2(x + w - r, y + h - r), r, 0, PI / 2, 4))
	p.append_array(arc_pts(Vector2(x + r, y + h - r), r, PI / 2, PI, 4))
	p.append_array(arc_pts(Vector2(x + r, y + r), r, PI, PI * 1.5, 4))
	shape(p, fill, ow)

func glow(c: Vector2, r: float, color: Color, a: float) -> void:
	draw_texture_rect(glow_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false, Color(color, a))

func t_now() -> float:
	return rig.t if rig else 0.0

# ---------- drawing ----------
func _draw() -> void:
	match kind:
		"limb": _limb()
		"hand": _hand()
		"shoe": _shoe()
		"torso": _torso()
		"pack": _pack()
		"neck": _neck()
		"head": _head()
		"backhair": _backhair()
		"monkey": _monkey()
		"butterfly": _butterfly()
		"aura": glow(Vector2.ZERO, 70, Color("8c3cdc"), 0.28)
		"cape": _cape()
		"robe": _robe()
		"halo": _halo()

func _limb() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var a := Vector2.ZERO
	var b := Vector2(0, seg)
	cap(a, b, wid + 1.7, OL)
	cap(a, b, wid, col)
	ln(Vector2(wid * 0.2, 0.4), Vector2(wid * 0.2, seg), Color(0, 0, 0, 0.16), wid * 0.35)
	ln(Vector2(-wid * 0.22, 0.2), Vector2(-wid * 0.22, seg - 0.4), Color(1, 1, 1, 0.22), maxf(0.5, wid * 0.28))

func _hand() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	circ(Vector2.ZERO, 2.15, OL)
	circ(Vector2.ZERO, 1.6, C("skin"))
	circ(Vector2(-0.5, -0.5), 0.6, Color(1, 1, 1, 0.25))
	var it = L("item")
	if it == "cane":
		ln(Vector2.ZERO, Vector2(1.4, 10), OL, 2.2)
		ln(Vector2.ZERO, Vector2(1.4, 10), Color("9a6a3a"), 1.3)
	elif it == "bible":
		rrect(-1.5, -2.8, 5, 6, 0.8, Color("3a2a5a"), 0.6)
		draw_rect(Rect2(0.6, -2, 0.7, 4), Color("ffd25a"))
		draw_rect(Rect2(-0.2, -0.6, 2.4, 0.7), Color("ffd25a"))
	elif it == "club":
		var e := Vector2(0, 13)
		ln(Vector2.ZERO, e, OL, 4.4)
		ln(Vector2.ZERO, e, Color("6a4028"), 3.0)
		circ(e, 3.8, OL)
		circ(e, 3.2, Color("7a4a30"))
	elif it == "orb":
		glow(Vector2(1, -1), 8, Color("aa3ce6"), 0.7)
		circ(Vector2(1, -1), 2.4, Color("8a3ab0"))
		circ(Vector2(0.4, -1.6), 0.8, Color("ff4b5c"))
	elif it == "staff":
		ln(Vector2(0, 8), Vector2(0.6, -16), OL, 2.4)
		ln(Vector2(0, 8), Vector2(0.6, -16), Color("8a5a2a"), 1.5)
		draw_arc(Vector2(-1.2, -16), 1.8, PI, TAU, 8, Color("8a5a2a"), 1.4, false)
	elif it == "sling":
		ln(Vector2.ZERO, Vector2(2, 5), Color("6a4a2a"), 0.6)
		ln(Vector2.ZERO, Vector2(-2, 5), Color("6a4a2a"), 0.6)
		circ(Vector2(0, 5.6), 1.4, Color("9a9a9a"))
	elif it == "trumpet":
		ln(Vector2(-1, 0), Vector2(5, -2), Color("d8b040"), 1.2)
		draw_colored_polygon(PackedVector2Array([Vector2(5, -2), Vector2(8, -4.5), Vector2(8.6, 0.6)]), Color("ffd25a"))
	elif it == "mic":
		ln(Vector2.ZERO, Vector2(1.8, -3.4), Color("222222"), 1.4)
		circ(Vector2(2.3, -4.3), 1.7, OL)
		circ(Vector2(2.3, -4.3), 1.3, Color("aaaaaa"))

func _shoe() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var p := PackedVector2Array([Vector2(-2.2, -1.9)])
	p.append_array(quad(Vector2(-2.2, -1.9), Vector2(1, -2.9), Vector2(3.3, -0.5)))
	p.append_array(quad(Vector2(3.3, -0.5), Vector2(4.8, 1.3), Vector2(2.8, 1.7)))
	p.append(Vector2(-2.3, 1.7))
	var sc := C("shoe")
	shape(p, sc, 0.9)
	draw_rect(Rect2(-2, 0.7, 5.8, 0.9), Color("d8d8e0") if sc.v > 0.95 else Color(1, 1, 1, 0.55))
	circ(Vector2(0.4, -1.6), 0.5, Color(1, 1, 1, 0.3))

func _torso_dims() -> Array:
	var mus: bool = L("muscle", false)
	return [6.9 if mus else 5.6, 5.0 if mus else 4.4, 10.4]

func _torso() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var d := _torso_dims()
	var sw: float = d[0]
	var ww: float = d[1]
	var TH: float = d[2]
	var top := Color("f4f6fa") if L("coat", false) else C("shirt")
	var pts := PackedVector2Array([Vector2(-ww, 0.6), Vector2(-sw, -TH + 2.6)])
	pts.append_array(quad(Vector2(-sw, -TH + 2.6), Vector2(-sw, -TH), Vector2(-sw + 2.4, -TH), 5))
	pts.append(Vector2(sw - 2.4, -TH))
	pts.append_array(quad(Vector2(sw - 2.4, -TH), Vector2(sw, -TH), Vector2(sw, -TH + 2.6), 5))
	pts.append(Vector2(ww, 0.6))
	var cols := PackedColorArray()
	for v in pts:
		var k := clampf(((v.x + sw) / (2 * sw) + (v.y + TH) / TH) * 0.5, 0, 1)
		cols.append(shade(top, 0.14).lerp(shade(top, -0.1), k))
	draw_polygon(pts, cols)
	# back side in shade
	draw_colored_polygon(PackedVector2Array([Vector2(-ww, 0.6), Vector2(-sw, -TH + 2.6), Vector2(-sw + 0.5, -TH + 0.6), Vector2(-sw * 0.3, -TH), Vector2(-ww * 0.3, 0.6)]), Color(0, 0, 0, 0.16))
	if L("coat", false):
		draw_rect(Rect2(-0.4, -TH, 3, TH), C("shirt"))
		ln(Vector2(2.6, -TH + 2), Vector2(2, -0.5), Color(0, 0, 0, 0.18), 0.5)
		draw_arc(Vector2(1.4, -TH + 3.2), 2.6, -0.4, 2.4, 10, Color("8a8a9a"), 0.7, false)
		circ(Vector2(3, -TH + 5.8), 0.9, Color("bbbbbb"))
	if L("suit", false):
		draw_colored_polygon(PackedVector2Array([Vector2(-0.6, -TH), Vector2(3.6, -TH), Vector2(1.5, -TH + 5.4)]), Color.WHITE)
		ln(Vector2(1.5, -TH + 0.6), Vector2(1.3, -TH + 6.8), Color("0b0b12"), 1.3)
		draw_polyline(PackedVector2Array([Vector2(-1, -TH), Vector2(1.4, -TH + 6), Vector2(3.8, -TH)]), Color(1, 1, 1, 0.22), 0.5, false)
		circ(Vector2(2.4, -3.4), 0.5, Color("444444"))
		circ(Vector2(2.4, -5.4), 0.5, Color("444444"))
	if L("bib", false):
		rrect(-1.8, -6.6, 5.2, 4.2, 0.6, Color.WHITE, 0.4)
		draw_rect(Rect2(-0.8, -5.2, 3.2, 0.7), Color("e8463c"))
		draw_rect(Rect2(-0.8, -3.8, 2.2, 0.6), Color("e8463c"))
	if L("tie") != null:
		ln(Vector2(1.3, -TH + 0.6), Vector2(1.3, -2.6), C("tie"), 1.6)
	if L("muscle", false) and not L("shadow", false):
		draw_arc(Vector2(1.2, -TH + 3.8), 2.4, 0.3, 2.6, 10, Color(0, 0, 0, 0.24), 0.6, false)
		ln(Vector2(1.2, -TH + 5.6), Vector2(1.2, -2.6), Color(0, 0, 0, 0.16), 0.5)
	if not L("coat", false) and not L("suit", false) and not L("shadow", false):
		draw_arc(Vector2(1, -TH), 2.4, 0.2, PI - 0.2, 10, Color(0, 0, 0, 0.25), 0.6, false)
	draw_rect(Rect2(-sw + 1.6, -TH + 0.2, 2 * sw - 3.2, 1.1), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(-ww - 0.3, -2.4, 2 * ww + 0.6, 3.0), C("pants"))
	draw_rect(Rect2(-ww - 0.3, -2.4, 2 * ww + 0.6, 0.7), Color(0, 0, 0, 0.28))
	var q := pts.duplicate()
	q.append(pts[0])
	draw_polyline(q, OL, 1.1, false)
	if L("shawl") != null:
		ln(Vector2(-sw + 0.4, -TH + 1.2), Vector2(sw - 0.4, -TH + 2.2), OL, 4.4)
		ln(Vector2(-sw + 0.4, -TH + 1.2), Vector2(sw - 0.4, -TH + 2.2), C("shawl"), 3.4)

func _pack() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var d := _torso_dims()
	var sw: float = d[0]
	var TH: float = d[2]
	rrect(-sw - 3.6, -TH + 1.2, 4.8, 8.6, 1.8, C("pack"), 0.9)
	draw_rect(Rect2(-sw - 3, -TH + 4, 3.6, 1.3), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-sw - 3, -TH + 1.8, 1.2, 7), Color(1, 1, 1, 0.18))

func _neck() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	cap(Vector2.ZERO, Vector2(0, -4.6), 4.0, OL)
	cap(Vector2.ZERO, Vector2(0, -4.6), 2.6, shade(C("skin"), -0.12))

func _backhair() -> void:
	var k := K * hs
	draw_set_transform(Vector2.ZERO, 0, Vector2(k, k))
	var hair := C("hair")
	var st = L("style", "none")
	var p := PackedVector2Array()
	match st:
		"long":
			p = PackedVector2Array([Vector2(-6.4, -2), Vector2(-6.4, 9)])
			p.append_array(quad(Vector2(-6.4, 9), Vector2(-3, 10), Vector2(0, 8)))
			p.append(Vector2(0, -2))
		"medium":
			p = PackedVector2Array([Vector2(-6.6, -2), Vector2(-6.2, 6)])
			p.append_array(quad(Vector2(-6.2, 6), Vector2(-3, 7.5), Vector2(-0.5, 5)))
			p.append(Vector2(0, -2))
		"bangs":
			p = PackedVector2Array([Vector2(-6.6, -2), Vector2(-6.4, 4)])
			p.append_array(quad(Vector2(-6.4, 4), Vector2(-3.5, 5), Vector2(-1, 3.5)))
			p.append(Vector2(0, -2))
		"ponytail":
			var sw := sin(t_now() * 0.1) * 0.8
			p = PackedVector2Array([Vector2(-5, -3)])
			p.append_array(quad(Vector2(-5, -3), Vector2(-12, -1 + sw), Vector2(-9 + sw, 7)))
			p.append_array(quad(Vector2(-9 + sw, 7), Vector2(-8, 1), Vector2(-4, 0)))
		"dreads":
			for i in 7:
				var sw := sin(t_now() * 0.12 + i) * 1.2
				var a := Vector2(-6 + i * 1.3, -3)
				var line := PackedVector2Array([a])
				line.append_array(quad(a, a + Vector2(-2, 6), a + Vector2(-2 + sw - i * 0.3, 11 - i * 0.6)))
				draw_polyline(line, OL, 2.6, false)
				draw_polyline(line, hair, 1.7, false)
				draw_polyline(line, Color(1, 1, 1, 0.08), 0.5, false)
	if p.size() > 2:
		shape(p, hair, 0.8)

func _head() -> void:
	var k := K * hs
	draw_set_transform(Vector2.ZERO, 0, Vector2(k, k))
	var skin := C("skin")
	var hair := C("hair")
	var st = L("style", "none")
	var shadow: bool = L("shadow", false)
	if st != "long" and st != "medium" and not shadow:
		circ(Vector2(-5.3, 1.2), 1.9, OL)
		circ(Vector2(-5.3, 1.2), 1.25, shade(skin, -0.12))
	circ(Vector2.ZERO, 6.9, OL)
	circ(Vector2.ZERO, 6.1, skin)
	glow(Vector2(-1.6, -2.6), 4.5, Color.WHITE, 0.16)
	var cres := arc_pts(Vector2.ZERO, 6.1, 0.3, 2.6, 12)
	cres.append_array(arc_pts(Vector2(0.8, -1), 5.0, 2.6, 0.3, 12))
	draw_colored_polygon(cres, Color(0, 0, 0, 0.13))
	if st != "none":
		if st == "curly":
			for i in range(-2, 3):
				circ(Vector2(i * 2.6 - 1, -4.8), 3.0, OL)
			for i in range(-2, 3):
				circ(Vector2(i * 2.6 - 1, -4.8), 2.5, hair)
				circ(Vector2(i * 2.6 - 1.6, -5.6), 0.8, Color(1, 1, 1, 0.08))
			circ(Vector2(-5, -1.5), 2.6, hair)
		else:
			var p := PackedVector2Array([Vector2(-6.5, 1.5)])
			p.append_array(arc_pts(Vector2.ZERO, 6.5, PI, TAU - 0.25, 14))
			p.append(Vector2(-3, -2.6))
			shape(p, hair, 0.8)
			draw_arc(Vector2.ZERO, 5.6, PI * 1.2, PI * 1.55, 6, Color(1, 1, 1, 0.12), 0.8, false)
			if st == "bun":
				circ(Vector2(-3, -7.4), 3.4, OL)
				circ(Vector2(-3, -7.4), 2.8, hair)
			elif st == "bangs":
				shape(PackedVector2Array([Vector2(-1, -6.2), Vector2(6.3, -3.8), Vector2(6.2, -1.6), Vector2(4.8, -2.8), Vector2(3.6, -1.4), Vector2(2.4, -2.8), Vector2(1, -1.6), Vector2(0, -3)]), hair, 0.8)
			elif st == "straight":
				shape(PackedVector2Array([Vector2(-3, -6.5), Vector2(6.7, -4.2), Vector2(6.4, -1.7), Vector2(5, -3), Vector2(4.1, -1.1), Vector2(2.8, -2.9), Vector2(1.6, -1.3), Vector2(0.5, -3.2), Vector2(-1.2, -2)]), hair, 0.8)
				draw_colored_polygon(PackedVector2Array([Vector2(-6.5, -2), Vector2(-6.6, 2.6), Vector2(-4.4, 1)]), hair)
			elif st == "medium" or st == "long":
				var q := PackedVector2Array([Vector2(0, -6.4)])
				q.append_array(quad(Vector2(0, -6.4), Vector2(6, -6), Vector2(6.3, -2.2)))
				q.append_array(quad(Vector2(6.3, -2.2), Vector2(3, -4.4), Vector2(-1, -3.4)))
				draw_colored_polygon(q, hair)
	if L("flower", false):
		for i in 5:
			circ(Vector2(-2, -6.2) + Vector2.from_angle(i * TAU / 5) * 1.0, 0.9, Color("ff6fa8"))
		circ(Vector2(-2, -6.2), 0.7, Color("ffe04a"))
	if L("band") != null:
		draw_rect(Rect2(-6.4, -4.2, 12.6, 1.7), C("band"))
	if L("horns", false):
		var hc := Color("6a4a7a")
		shape(PackedVector2Array([Vector2(-3.5, -5), Vector2(-5, -11), Vector2(-1, -5.8)]), hc, 0.6)
		shape(PackedVector2Array([Vector2(2, -5.6), Vector2(4, -11), Vector2(5.4, -4.4)]), hc, 0.6)
	if L("eye") != null:
		glow(Vector2(3.2, -0.6), 6, Color("ff3c50"), 0.5)
		var ec := C("eye")
		draw_colored_polygon(ell_pts(Vector2(1.8, -0.6), 1.5, 1.0, 0.25), ec)
		draw_colored_polygon(ell_pts(Vector2(4.8, -0.6), 1.3, 1.0, -0.25), ec)
	else:
		var bl: float = rig.blink if rig else 1.0
		var ring := Color(0.1, 0.08, 0.19, 0.6)
		var e1 := ell_pts(Vector2(2.1, -0.3), 1.5, 1.95 * bl)
		var e2 := ell_pts(Vector2(4.9, -0.3), 1.35, 1.95 * bl)
		draw_colored_polygon(e1, Color.WHITE)
		draw_colored_polygon(e2, Color.WHITE)
		e1.append(e1[0])
		e2.append(e2[0])
		draw_polyline(e1, ring, 0.35, false)
		draw_polyline(e2, ring, 0.35, false)
		if bl > 0.5:
			var look_dx: float = rig.look_dx if rig else 0.0
			circ(Vector2(2.7 + look_dx, -0.1), 1.05, Color("3a2210"))
			circ(Vector2(5.4 + look_dx, -0.1), 0.95, Color("3a2210"))
			circ(Vector2(2.8 + look_dx, 0), 0.55, Color("0e0810"))
			circ(Vector2(5.5 + look_dx, 0), 0.5, Color("0e0810"))
			circ(Vector2(2.95 + look_dx, -0.6), 0.38, Color.WHITE)
			circ(Vector2(5.6 + look_dx, -0.6), 0.33, Color.WHITE)
		if st != "none" and not L("shades", false):
			var bc := Color("bbbbbb") if L("hair") == "#f4f4f4" else shade(hair, -0.1)
			var lift: float = rig.brow if rig else 0.0
			ln(Vector2(0.9, -2.9 - lift), Vector2(3, -3.3 - lift * 0.4), bc, 0.75)
			ln(Vector2(4, -3.3 - lift * 0.4), Vector2(6, -2.8 - lift), bc, 0.75)
		var mo: bool = rig.mouth_open if rig else false
		if mo:
			draw_colored_polygon(ell_pts(Vector2(3.7, 2.5), 1.2, 1.0), Color("5a1a1a"))
			circ(Vector2(3.7, 3.0), 0.5, Color("e86a7a"))
		else:
			draw_arc(Vector2(3.6, 2.2), 1.4, 0.3, 2.6, 10, Color("7a2a2a"), 0.6, false)
		circ(Vector2(5.4, 1.6), 1.0, Color(1, 0.43, 0.47, 0.35))
	if L("visor", false):
		rrect(0.4, -2.2, 6.4, 2.8, 1, Color(0.24, 0.94, 1.0, 0.8), 0.5)
		glow(Vector2(3.5, -0.8), 7, Color("3ef0ff"), 0.35)
	if L("glasses", false):
		var gc := Color("1a1020")
		circ(Vector2(2, -0.4), 1.7, Color(0.7, 0.86, 1, 0.25))
		circ(Vector2(5, -0.4), 1.6, Color(0.7, 0.86, 1, 0.25))
		draw_arc(Vector2(2, -0.4), 1.7, 0, TAU, 16, gc, 0.6, false)
		draw_arc(Vector2(5, -0.4), 1.6, 0, TAU, 16, gc, 0.6, false)
		ln(Vector2(3.6, -0.6), Vector2(3.5, -0.6), gc, 0.6)
		ln(Vector2(0.4, -0.6), Vector2(-3, -1), gc, 0.5)
	if L("shades", false):
		var sc := Color("0b0b12")
		rrect(0.3, -2, 3.1, 2.4, 0.9, sc)
		rrect(3.7, -2, 2.8, 2.4, 0.9, sc)
		ln(Vector2(3.3, -1.3), Vector2(3.8, -1.3), sc, 0.7)
		ln(Vector2(0.4, -1.3), Vector2(-3.2, -1.7), sc, 0.6)
		ln(Vector2(1, -1.5), Vector2(2.2, -1.5), Color(1, 1, 1, 0.65), 0.4)
	if L("beard") != null:
		draw_colored_polygon(arc_pts(Vector2(1.5, 1.6), 4.4, 0.1, PI - 0.3, 12), C("beard"))

func _monkey() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var t := t_now()
	var hop := absf(sin(t * 0.15)) * 2.0
	var o := Vector2(0, -hop)
	var tail := PackedVector2Array([o + Vector2(-2, -3)])
	tail.append_array(quad(o + Vector2(-2, -3), o + Vector2(-7, -2), o + Vector2(-6, -7)))
	tail.append_array(quad(o + Vector2(-6, -7), o + Vector2(-5, -9 + sin(t * 0.2)), o + Vector2(-3.5, -8)))
	draw_polyline(tail, Color("5a3418"), 1.3, false)
	circ(o + Vector2(0, -3.5), 3.4, OL)
	circ(o + Vector2(0, -3.5), 2.8, Color("7a4a24"))
	circ(o + Vector2(0.8, -8.2), 3.0, OL)
	circ(o + Vector2(0.8, -8.2), 2.5, Color("7a4a24"))
	circ(o + Vector2(-1.6, -9.5), 1.2, Color("7a4a24"))
	circ(o + Vector2(1.6, -7.8), 1.6, Color("e8c09a"))
	circ(o + Vector2(2.2, -8.6), 0.5, Color("111111"))
	ln(o + Vector2(-1, -1), o + Vector2(-1.5, 0), Color("5a3418"), 1.4)
	ln(o + Vector2(1.2, -1), o + Vector2(1.8, 0), Color("5a3418"), 1.4)

func _butterfly() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var t := t_now()
	var f := 0.35 + absf(sin(t * 0.4)) * 0.65
	var c := C("butterfly")
	for m in [-1.0, 1.0]:
		var w1 := ell_pts(Vector2(m * 2.4 * f, -1.2), 2.6 * f, 2.0, m * 0.5, 14)
		shape(w1, c, 0.4)
		var w2 := ell_pts(Vector2(m * 1.8 * f, 1.4), 1.7 * f, 1.4, -m * 0.4, 12)
		shape(w2, shade(c, -0.15), 0.4)
	draw_rect(Rect2(-0.4, -2.4, 0.8, 4.6), Color("222222"))

func _cape() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var t := t_now()
	var sp: float = clampf(absf(rig.vel.x) / 450.0, 0.0, 1.0) if rig else 0.0
	var fl := sin(t * 0.25) * (0.6 + sp)
	var p := PackedVector2Array([Vector2(-4.5, -10), Vector2(3.5, -10)])
	p.append_array(quad(Vector2(3.5, -10), Vector2(2 - sp * 3, -2), Vector2(-3 - sp * 9 + fl, 4 + fl * 0.5)))
	p.append(Vector2(-6 - sp * 10 + fl, 2 - sp * 3))
	p.append_array(quad(Vector2(-6 - sp * 10 + fl, 2 - sp * 3), Vector2(-7 - sp * 4, -4), Vector2(-4.5, -10)))
	shape(p, Color("7a3fc0"), 0.9)
	ln(Vector2(-4.5, -10.2), Vector2(3.5, -10.2), Color("ffd25a"), 1.4)

func _halo() -> void:
	glow(Vector2.ZERO, 40, Color("ffdc64"), 0.5)
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.32))
	draw_arc(Vector2.ZERO, 18, 0, TAU, 32, Color("ffe27a"), 6, false)

func _robe() -> void:
	# a long tunic for the Bible characters, hanging from the waist to the shins
	draw_set_transform(Vector2.ZERO, 0, Vector2(K, K))
	var c := C("robe")
	var t := t_now()
	var sw := sin(t * 0.12) * 0.6 + (clampf(rig.vel.x / 450.0, -1, 1) * -1.5 if rig else 0.0)
	var p := PackedVector2Array([Vector2(-4.6, -1), Vector2(4.6, -1), Vector2(6.0 + sw, 8.5), Vector2(-6.0 + sw, 8.5)])
	shape(p, c, 0.9)
	draw_colored_polygon(PackedVector2Array([Vector2(-4.6, -1), Vector2(-1.5, -1), Vector2(-2.5 + sw, 8.5), Vector2(-6.0 + sw, 8.5)]), Color(0, 0, 0, 0.15))
	ln(Vector2(-4.4, 0), Vector2(4.4, 0), shade(c, -0.3), 1.2)
