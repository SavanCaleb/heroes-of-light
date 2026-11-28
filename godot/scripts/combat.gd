extends RefCounted
## Combat visuals and moving attacks: swooshes, shockwave rings, light pillars and projectiles.

const Part := preload("res://scripts/part.gd")
const OL := Color("1b1430")

static func add_mat() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

## A bright crescent that follows a punch or kick, so every hit reads clearly.
class Swoosh extends Node2D:
	var radius := 60.0
	var a0 := -1.0
	var sweep := 2.0
	var width := 18.0
	var col := Color(1, 0.95, 0.7)
	var life := 0.2
	var t := 0.0
	func _ready() -> void:
		material = Combat_add()
		z_index = 6
	func _process(d: float) -> void:
		t += d
		if t >= life:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / life
		var grow := minf(1.0, k * 3.0)
		var n := 18
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var cols := PackedColorArray()
		for i in n + 1:
			var f := float(i) / n
			if f > grow:
				break
			var a := a0 + sweep * f
			var w := width * sin(f * PI) * (1.0 - k)
			outer.append(Vector2.from_angle(a) * radius)
			inner.append(Vector2.from_angle(a) * (radius - w))
		if outer.size() < 2:
			return
		var pts := PackedVector2Array()
		pts.append_array(outer)
		var rin := inner.duplicate()
		rin.reverse()
		pts.append_array(rin)
		for i in pts.size():
			cols.append(Color(col, (0.95 - k) * (0.4 + 0.6 * float(i % outer.size()) / outer.size())))
		draw_polygon(pts, cols)
		draw_texture_rect(Part.glow_tex(), Rect2(Vector2.from_angle(a0 + sweep * 0.5) * radius - Vector2(30, 30), Vector2(60, 60)), false, Color(col, 0.5 * (1 - k)))
	static func Combat_add() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

## Expanding ring that hits everything it reaches once (stomps, praise, shockwaves).
class Ring extends Node2D:
	var main
	var team := "hero"
	var r := 10.0
	var max_r := 200.0
	var speed := 900.0
	var dmg := 10.0
	var kb := 4.0
	var up := 4.0
	var col := Color(1, 0.9, 0.6)
	var flat := false
	var hitset := {}
	var heal := 0.0
	func _ready() -> void:
		z_index = 5
		material = Swoosh.Combat_add()
	func _physics_process(d: float) -> void:
		r += speed * d
		if r >= max_r:
			queue_free()
			return
		if dmg > 0:
			main.ring_hit(self)
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - r / max_r
		if flat:
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.28))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col, a), 10.0 * a + 2, false)
		draw_arc(Vector2.ZERO, r * 0.82, 0, TAU, 48, Color(col, a * 0.5), 4, false)
		draw_texture_rect(Part.glow_tex(), Rect2(-r, -r, r * 2, r * 2), false, Color(col, a * 0.25))

## A column of light that slams down from the sky (used by SUPER moves).
class Pillar extends Node2D:
	var t := 0.0
	var col := Color(1, 0.92, 0.6)
	var on_hit: Callable
	var fired := false
	func _ready() -> void:
		z_index = 7
		material = Swoosh.Combat_add()
	func _process(d: float) -> void:
		t += d
		if t > 0.12 and not fired:
			fired = true
			if on_hit.is_valid():
				on_hit.call()
		if t > 0.7:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var drop := minf(1.0, t / 0.12)
		var a := 1.0 if t < 0.3 else maxf(0.0, 1.0 - (t - 0.3) / 0.4)
		var top := -900.0
		var bottom := lerpf(top, 0.0, drop)
		var w := 34.0 + sin(t * 40.0) * 4.0
		draw_rect(Rect2(-w, top, w * 2, bottom - top), Color(col, 0.35 * a))
		draw_rect(Rect2(-w * 0.45, top, w * 0.9, bottom - top), Color(1, 1, 1, 0.8 * a))
		if drop >= 1.0:
			draw_texture_rect(Part.glow_tex(), Rect2(-110, -110, 220, 220), false, Color(col, 0.8 * a))

## Anything that flies: hero skills and enemy shots.
class Proj extends Node2D:
	var main
	var kind := "orb"
	var team := "foe"
	var vel := Vector2.ZERO
	var grav := 0.0
	var dmg := 8.0
	var kb := 2.5
	var up := 2.0
	var life := 3.0
	var pierce := false
	var homing := false
	var bounce := false
	var r := 14.0
	var col := Color.WHITE
	var hitset := {}
	var t := 0.0
	var look := {}
	func _ready() -> void:
		z_index = 5
	func _physics_process(d: float) -> void:
		t += d
		life -= d
		if life <= 0.0:
			queue_free()
			return
		if homing:
			var tg = main.nearest_enemy(position, team, 600.0)
			if tg:
				var want: Vector2 = (tg.center() - position).normalized() * 520.0
				vel = vel.lerp(want, 1.0 - exp(-d * 3.5))
		vel.y += grav * d
		position += vel * d
		if bounce and vel.y > 0 and main.level.solid(int(position.x / 48.0), int((position.y + r) / 48.0)):
			position.y = int((position.y + r) / 48.0) * 48.0 - r
			vel.y = -absf(vel.y) * 0.7 - 200.0
		var box := Rect2(position - Vector2(r, r), Vector2(r, r) * 2)
		if main.strike_box(self, box, dmg, kb, up) and not pierce:
			main.spark(position, col)
			queue_free()
			return
		if not pierce and not bounce and main.level.solid(int(position.x / 48.0), int(position.y / 48.0)):
			main.spark(position, col)
			queue_free()
			return
		queue_redraw()
	func _draw() -> void:
		var g := Part.glow_tex()
		match kind:
			"monkey":
				draw_set_transform(Vector2.ZERO, sin(t * 20.0) * 0.4, Vector2(4.5, 4.5) * signf(vel.x if vel.x != 0 else 1.0))
				draw_circle(Vector2(0, 0), 3.4, OL)
				draw_circle(Vector2(0, 0), 2.8, Color("7a4a24"))
				draw_circle(Vector2(0.8, -4.2), 3.0, OL)
				draw_circle(Vector2(0.8, -4.2), 2.5, Color("7a4a24"))
				draw_circle(Vector2(1.6, -3.8), 1.6, Color("e8c09a"))
				draw_circle(Vector2(2.2, -4.6), 0.5, Color("111111"))
			"butterfly":
				draw_texture_rect(g, Rect2(-24, -24, 48, 48), false, Color(col, 0.4))
				var f := 0.35 + absf(sin(t * 24.0)) * 0.65
				for m in [-1.0, 1.0]:
					draw_colored_polygon(Part.ell_pts(Vector2(m * 7 * f, -3), 8 * f, 6, m * 0.5, 12), col)
					draw_colored_polygon(Part.ell_pts(Vector2(m * 5 * f, 4), 5 * f, 4, -m * 0.4, 10), col.darkened(0.2))
				draw_rect(Rect2(-1, -7, 2, 14), Color("222222"))
			"laser":
				draw_texture_rect(g, Rect2(-30, -30, 60, 60), false, Color(0.25, 0.95, 1, 0.6))
				draw_line(Vector2.ZERO, -vel.normalized() * 40.0, Color(0.75, 0.98, 1), 6, false)
				draw_line(Vector2.ZERO, -vel.normalized() * 34.0, Color.WHITE, 2.5, false)
			"sword":
				draw_set_transform(Vector2.ZERO, 0, Vector2(signf(vel.x), 1))
				draw_texture_rect(g, Rect2(-70, -70, 140, 140), false, Color(0.7, 0.85, 1, 0.5))
				draw_arc(Vector2(-20, 0), 40, -1.2, 1.2, 20, Color(0.8, 0.92, 1), 10, false)
				draw_arc(Vector2(-20, 0), 40, -1.1, 1.1, 20, Color.WHITE, 4, false)
			"orb":
				draw_texture_rect(g, Rect2(-28, -28, 56, 56), false, Color(0.63, 0.2, 0.86, 0.7))
				draw_circle(Vector2.ZERO, 11, Color("3a1050"))
				draw_circle(Vector2(-2, -2), 4, Color("ff4b5c"))
			"venom":
				draw_texture_rect(g, Rect2(-24, -24, 48, 48), false, Color(0.6, 1, 0.4, 0.6))
				draw_circle(Vector2.ZERO, 9, Color("9aff6a"))
				draw_circle(Vector2.ZERO, 5, Color("4ac02a"))
			"fire":
				draw_texture_rect(g, Rect2(-34, -34, 68, 68), false, Color(1, 0.4, 0.15, 0.8))
				draw_circle(Vector2.ZERO, 12, Color("ff7a2a"))
				draw_circle(Vector2.ZERO, 6, Color("ffe04a"))
			"band":
				var o = look.get("owner")
				if o and is_instance_valid(o):
					var hand: Vector2 = o.center() + Vector2(o.face * 10, -6) - position
					draw_line(hand, Vector2.ZERO, OL, 9, false)
					draw_line(hand, Vector2.ZERO, Color("ff6a3a"), 6, false)
				draw_rect(Rect2(-8, -8, 16, 16), Color("ffd25a"))
			_:
				draw_texture_rect(g, Rect2(-24, -24, 48, 48), false, Color(col, 0.7))
				draw_circle(Vector2.ZERO, r * 0.6, col)
