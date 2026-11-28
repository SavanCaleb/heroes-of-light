extends RefCounted
## Shared drawing for menus and the in-game HUD: glass panels, buttons, text, stars, coins and shop icons.

const GOLD := Color("ffd25a")
const INK := Color("1b1430")
const CREAM := Color("fff6d8")
const Part := preload("res://scripts/part.gd")

static func font() -> Font:
	return ThemeDB.fallback_font

static func panel(ci: CanvasItem, r: Rect2, sel := false, alpha := 0.92) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.1, 0.28, alpha) if not sel else Color(0.24, 0.18, 0.45, alpha)
	sb.border_color = Color(GOLD, 1.0 if sel else 0.35)
	sb.set_border_width_all(4 if sel else 2)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)
	if sel:
		ci.draw_texture_rect(Part.glow_tex(), r.grow(30), false, Color(GOLD, 0.12))

static func button(ci: CanvasItem, r: Rect2, label: String, primary := false, size := 30) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffc93a") if primary else Color("3a2f6e")
	sb.border_color = Color("fff2c0") if primary else Color(GOLD, 0.6)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(r.size.y / 2))
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)
	var hi := StyleBoxFlat.new()
	hi.bg_color = Color(1, 1, 1, 0.22)
	hi.set_corner_radius_all(int(r.size.y / 2))
	hi.anti_aliasing = true
	ci.draw_style_box(hi, Rect2(r.position + Vector2(8, 5), Vector2(r.size.x - 16, r.size.y * 0.38)))
	text_c(ci, label, r.get_center(), size, INK if primary else CREAM, 0 if primary else 6)

## Text with its baseline at `p`; `align` uses the width `w`.
static func text(ci: CanvasItem, s: String, p: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0, outline := 7) -> void:
	if outline > 0:
		ci.draw_string_outline(font(), p, s, align, w, size, outline, Color(INK, 0.9))
	ci.draw_string(font(), p, s, align, w, size, col)

## Text centred on a point.
static func text_c(ci: CanvasItem, s: String, c: Vector2, size: int, col: Color, outline := 7) -> void:
	var sz := font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	text(ci, s, c + Vector2(-sz.x / 2, size * 0.36), size, col, HORIZONTAL_ALIGNMENT_LEFT, -1, outline)

static func wrap(s: String, w: float, size: int) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in s.split(" "):
		var t := word if line == "" else line + " " + word
		if font().get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w and line != "":
			out.append(line)
			line = word
		else:
			line = t
	if line != "":
		out.append(line)
	return out

static func star(ci: CanvasItem, c: Vector2, r: float, on: bool) -> void:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		p.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
	if on:
		ci.draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(r, r) * 2, Vector2(r, r) * 4), false, Color(GOLD, 0.45))
	var q := p.duplicate()
	q.append(p[0])
	ci.draw_colored_polygon(p, GOLD if on else Color("3a2f5a"))
	ci.draw_polyline(q, INK, 3, true)

static func coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r + 3, INK, true, -1, true)
	ci.draw_circle(c, r, Color("ffc93a"), true, -1, true)
	ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.45, Color("fff0a0"), true, -1, true)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.12, -r * 0.6), Vector2(r * 0.24, r * 1.2)), Color("b0640a"))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.3), Vector2(r * 0.8, r * 0.22)), Color("b0640a"))

static func coin_badge(ci: CanvasItem, p: Vector2, n: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.1, 0.75)
	sb.border_color = Color(GOLD, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, Rect2(p, Vector2(170, 46)))
	coin(ci, p + Vector2(26, 23), 13)
	text(ci, str(n), p + Vector2(50, 33), 28, Color("ffe27a"))

## Little drawings for the shop items, centred on `c`, about 60px across at s = 1.
static func icon(ci: CanvasItem, id: String, c: Vector2, s := 1.0) -> void:
	ci.draw_set_transform(c, 0, Vector2(s, s))
	var o := Vector2.ZERO
	ci.draw_texture_rect(Part.glow_tex(), Rect2(-44, -44, 88, 88), false, Color(1, 0.85, 0.5, 0.25))
	match id:
		"heart":
			var hp := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32
				hp.append(Vector2(16 * pow(sin(a), 3), -(13 * cos(a) - 5 * cos(2 * a) - 2 * cos(3 * a) - cos(4 * a)) - 2) * 1.5)
			ci.draw_colored_polygon(hp, Color("ff4b6a"))
			hp.append(hp[0])
			ci.draw_polyline(hp, INK, 3, true)
			ci.draw_circle(Vector2(-9, -10), 4, Color("ffc0cc"))
		"glove":
			_rr(ci, Rect2(-18, -20, 36, 30), 10, Color("e8463c"))
			_rr(ci, Rect2(-20, 8, 40, 14), 5, Color("f4f0e6"))
			for x in [-6, 4]:
				ci.draw_line(Vector2(x, -20), Vector2(x, -8), Color(0, 0, 0, 0.3), 2)
			ci.draw_rect(Rect2(-14, -16, 18, 5), Color(1, 1, 1, 0.35))
		"helmet":
			ci.draw_colored_polygon(Part.arc_pts(Vector2(0, 6), 22, PI, TAU, 16), Color("c8ccd8"))
			ci.draw_rect(Rect2(-24, 4, 48, 8), Color("9aa0b0"))
			ci.draw_rect(Rect2(-3, -16, 6, 28), Color("ffd25a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(14, -34), Vector2(6, -14)]), Color("e8463c"))
			ci.draw_arc(Vector2(0, 6), 22, PI, TAU, 16, INK, 3, true)
		"sandal":
			for i in 3:
				ci.draw_colored_polygon(Part.ell_pts(Vector2(-18 - i * 4, -8 + i * 7), 12 - i * 2, 4, -0.35), Color.WHITE)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, 12), Vector2(-14, -6), Vector2(-2, -10), Vector2(4, 0), Vector2(22, 4), Vector2(26, 12)]), Color("3a8ae8"))
			_rr(ci, Rect2(-18, 11, 46, 7), 3, Color("f4f0e6"))
		"wings":
			for m in [-1.0, 1.0]:
				for i in 4:
					ci.draw_colored_polygon(Part.ell_pts(Vector2(m * (8 + i * 6), -6 + i * 5), 14 - i * 2, 6, m * (0.6 + i * 0.15)), Color(1, 1, 1, 1.0 - i * 0.12))
			ci.draw_circle(Vector2.ZERO, 6, Color("ffd25a"))
		"oil":
			ci.draw_texture_rect(Part.glow_tex(), Rect2(4, -40, 40, 40), false, Color(1, 0.7, 0.3, 0.8))
			ci.draw_colored_polygon(Part.ell_pts(Vector2(-2, 6), 22, 12), Color("e0a030"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(28, -6), Vector2(20, 8)]), Color("e0a030"))
			ci.draw_colored_polygon(Part.ell_pts(Vector2(24, -16), 5, 9), Color("ffd04a"))
			ci.draw_circle(Vector2(24, -13), 3, Color("fff8c0"))
		"zeal":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -28), Vector2(16, -4), Vector2(14, 14), Vector2(0, 22), Vector2(-14, 14), Vector2(-16, -4)]), Color("ff6a2a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(8, 8), Vector2(0, 18), Vector2(-8, 8)]), Color("ffe04a"))
		"shield":
			var sp := PackedVector2Array([Vector2(-22, -22), Vector2(22, -22), Vector2(20, 4), Vector2(0, 26), Vector2(-20, 4)])
			ci.draw_colored_polygon(sp, Color("3a6ae8"))
			sp.append(sp[0])
			ci.draw_polyline(sp, Color("ffd25a"), 4, true)
			ci.draw_rect(Rect2(-3, -16, 6, 32), Color("ffd25a"))
			ci.draw_rect(Rect2(-12, -6, 24, 6), Color("ffd25a"))
		"magnet":
			ci.draw_arc(Vector2(0, 2), 14, 0, PI, 16, Color("e8463c"), 12, true)
			ci.draw_rect(Rect2(-20, -16, 12, 18), Color("e8463c"))
			ci.draw_rect(Rect2(8, -16, 12, 18), Color("e8463c"))
			ci.draw_rect(Rect2(-20, -22, 12, 8), Color("e8e8f0"))
			ci.draw_rect(Rect2(8, -22, 12, 8), Color("e8e8f0"))
			coin(ci, Vector2(22, -28), 7)
		"angel":
			for m in [-1.0, 1.0]:
				ci.draw_colored_polygon(Part.ell_pts(Vector2(m * 14, -4), 14, 7, m * -0.5), Color.WHITE)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, -2), Vector2(8, -2), Vector2(12, 24), Vector2(-12, 24)]), Color("fbf7ee"))
			ci.draw_circle(Vector2(0, -10), 8, Color("f3d2b8"))
			ci.draw_arc(Vector2(0, -22), 9, 0, TAU, 20, Color("ffd25a"), 3, true)
		"halo":
			ci.draw_texture_rect(Part.glow_tex(), Rect2(-36, -26, 72, 52), false, Color(1, 0.85, 0.4, 0.8))
			ci.draw_colored_polygon(Part.ell_pts(Vector2.ZERO, 24, 9), Color("ffd25a"))
			ci.draw_colored_polygon(Part.ell_pts(Vector2.ZERO, 16, 4), Color(0.14, 0.1, 0.28))
		"cape":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(26, 24), Vector2(8, 18), Vector2(0, 26), Vector2(-8, 18), Vector2(-26, 24)]), Color("7a3fc0"))
			ci.draw_rect(Rect2(-16, -26, 32, 6), Color("ffd25a"))
			ci.draw_line(Vector2(-6, -20), Vector2(-14, 20), Color(1, 1, 1, 0.2), 3)
		"rainbow":
			var cs := [Color("e8463c"), Color("ff9a3c"), Color("ffe04a"), Color("4fc36b"), Color("4fa0ff"), Color("9b5bff")]
			for i in cs.size():
				ci.draw_arc(Vector2(0, 14), 30 - i * 4.5, PI, TAU, 24, cs[i], 4.5, true)
			for x in [-30, 30]:
				for b in [[-6, 0, 8], [2, -4, 9], [9, 1, 7]]:
					ci.draw_circle(Vector2(x + b[0], 16 + b[1]), b[2], Color.WHITE)
	ci.draw_set_transform(Vector2.ZERO)

static func _rr(ci: CanvasItem, r: Rect2, rad: float, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(rad))
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)
