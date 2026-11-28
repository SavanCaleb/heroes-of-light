extends RefCounted
## Little visual effects: coins, hit sparks, damage numbers, doves, dust and the goal cross.

const Part := preload("res://scripts/part.gd")
const OL := Color("1b1430")

static func add_glow(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float) -> void:
	ci.draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2), false, Color(col, a))

static func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

## One-shot puff of soft particles.
static func burst(parent: Node, pos: Vector2, col: Color, n: int, speed: float, size := 0.09, up := 0.0, add := true) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = n
	p.lifetime = 0.6
	p.texture = Part.glow_tex()
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 600 - up)
	p.damping_min = 80
	p.damping_max = 160
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.3
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col, 0))
	p.color_ramp = g
	if add:
		p.material = additive()
	p.z_index = 6
	p.emitting = true
	parent.add_child(p)
	p.finished.connect(p.queue_free)

static func dust(parent: Node, pos: Vector2, n := 6, spread := 1.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = n
	p.lifetime = 0.5
	p.texture = Part.glow_tex()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14 * spread, 2)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 40
	p.initial_velocity_max = 110 * spread
	p.gravity = Vector2(0, 120)
	p.damping_min = 120
	p.damping_max = 200
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.24
	var g := Gradient.new()
	g.set_color(0, Color(0.95, 0.9, 0.8, 0.7))
	g.set_color(1, Color(0.95, 0.9, 0.8, 0))
	p.color_ramp = g
	p.z_index = 3
	p.emitting = true
	parent.add_child(p)
	p.finished.connect(p.queue_free)

class Coin extends Node2D:
	var t := randf() * 10.0
	var vel := Vector2.ZERO
	var loose := false
	var age := 0.0
	var base_y := 0.0
	func _ready() -> void:
		base_y = position.y
	func _process(d: float) -> void:
		t += d
		age += d
		if not loose:
			position.y = base_y + sin(t * 3.0) * 4.0
		queue_redraw()
	func _draw() -> void:
		var w := (absf(cos(t * 3.4)) * 13.0 + 2.5)
		draw_texture_rect(Part.glow_tex(), Rect2(-26, -26, 52, 52), false, Color(1, 0.82, 0.35, 0.35))
		draw_colored_polygon(_ell(w + 2.5, 17.0), OL)
		var pts := _ell(w, 14.5)
		var cols := PackedColorArray()
		for p in pts:
			cols.append(Color("fff6b0").lerp(Color("d07d0c"), clampf((p.x / maxf(w, 1.0) + p.y / 14.5) * 0.5 + 0.5, 0, 1)))
		draw_polygon(pts, cols)
		if w > 7.0:
			draw_rect(Rect2(-1.6, -8.5, 3.2, 17), Color("b0640a"))
			draw_rect(Rect2(-5, -4.6, 10, 3.2), Color("b0640a"))
		draw_rect(Rect2(-w * 0.55, -10.5, maxf(1.2, w * 0.3), 3.2), Color(1, 1, 1, 0.7))
	func _ell(rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20
			p.append(Vector2(cos(a) * rx, sin(a) * ry))
		return p

class Spark extends Node2D:
	var life := 0.16
	var t := 0.0
	var gold := false
	func _ready() -> void:
		rotation = randf() * TAU
		material = Fx_add()
		z_index = 7
	func _process(d: float) -> void:
		t += d
		if t > life:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / life
		var c := Color("ffe27a") if gold else Color(1, 1, 0.9)
		draw_texture_rect(Part.glow_tex(), Rect2(-50, -50, 100, 100), false, Color(c, 0.7 * (1 - k)))
		for i in 8:
			var a := i * TAU / 8
			var len := (14.0 + k * 34.0) * (1.0 if i % 2 == 0 else 0.55)
			draw_line(Vector2.from_angle(a) * (6 + k * 14), Vector2.from_angle(a) * len, Color(c, 1 - k), 4.0 * (1 - k) + 1.0, false)
	static func Fx_add() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

class Number extends Label:
	func setup(n: String, col: Color, big: bool) -> void:
		text = n
		var ls := LabelSettings.new()
		ls.font_size = 34 if big else 26
		ls.font_color = col
		ls.outline_size = 9
		ls.outline_color = Color("1b1430")
		ls.shadow_color = Color(0, 0, 0, 0.35)
		ls.shadow_offset = Vector2(2, 3)
		label_settings = ls
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		size = Vector2(120, 40)
		pivot_offset = Vector2(60, 20)
		z_index = 8
	func _ready() -> void:
		position -= Vector2(60, 20)
		scale = Vector2(0.4, 0.4)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08)
		tw.tween_property(self, "scale", Vector2(1, 1), 0.08)
		var tw2 := create_tween()
		tw2.tween_property(self, "position:y", position.y - 70, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw2.parallel().tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.45)
		tw2.tween_callback(queue_free)

class Dove extends Node2D:
	var t := 0.0
	var vel := Vector2(randf_range(-30, 30), -120)
	func _process(d: float) -> void:
		t += d
		position += vel * d
		vel.x += sin(t * 3.0) * 4.0
		modulate.a = clampf(2.6 - t, 0, 1)
		if t > 2.6:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var flap := sin(t * 18.0)
		draw_texture_rect(Part.glow_tex(), Rect2(-30, -30, 60, 60), false, Color(1, 1, 1, 0.35))
		draw_colored_polygon(_ell(Vector2.ZERO, 11, 5.5), Color.WHITE)
		for m in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(-3, 0), Vector2(m * 3, -14 * flap), Vector2(4, 0)]), Color(0.95, 0.95, 1))
		draw_circle(Vector2(10, -2), 4, Color.WHITE)
		draw_colored_polygon(PackedVector2Array([Vector2(13, -2), Vector2(18, -1), Vector2(13, 0)]), Color("ffb020"))
		draw_circle(Vector2(11, -3), 1, Color("1b1430"))
	func _ell(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16
			p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return p

class Goal extends Node2D:
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var pulse := 0.6 + sin(t * 3.0) * 0.15
		draw_texture_rect(Part.glow_tex(), Rect2(-200, -260, 400, 400), false, Color(1, 0.88, 0.55, pulse))
		for i in 8:
			var a := t * 0.4 + i * TAU / 8
			draw_colored_polygon(PackedVector2Array([Vector2(0, -60), Vector2(0, -60) + Vector2.from_angle(a - 0.08) * 260, Vector2(0, -60) + Vector2.from_angle(a + 0.08) * 260]), Color(1, 0.95, 0.75, 0.12))
		var wood := Color("8a5a2a")
		draw_rect(Rect2(-10, -150, 20, 150), OL)
		draw_rect(Rect2(-7, -147, 14, 147), wood)
		draw_rect(Rect2(-44, -116, 88, 20), OL)
		draw_rect(Rect2(-41, -113, 82, 14), wood)
		draw_rect(Rect2(-4, -145, 4, 140), Color("b07a42"))
		draw_rect(Rect2(-39, -110, 78, 4), Color("b07a42"))

class Candle extends Node2D:
	var lit := false
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		if lit:
			queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-6, -42, 12, 42), Color("1b1430"))
		draw_rect(Rect2(-4, -40, 8, 40), Color("f4ecd8"))
		draw_rect(Rect2(-14, -6, 28, 8), Color("8a6a46"))
		if lit:
			var f := sin(t * 18.0)
			draw_texture_rect(Part.glow_tex(), Rect2(-50, -100, 100, 100), false, Color(1, 0.75, 0.35, 0.7))
			draw_colored_polygon(_flame(f), Color("ffb020"))
			draw_circle(Vector2(0, -48), 3, Color("fff8c0"))
		else:
			draw_line(Vector2(0, -42), Vector2(0, -50), Color("333333"), 2)
	func _flame(f: float) -> PackedVector2Array:
		return PackedVector2Array([Vector2(0, -64 + f), Vector2(5, -50), Vector2(0, -43), Vector2(-5, -50)])
