extends Node2D
## The Serpent of Lies and Satan. (The Giant of Fear is a big Fighter.)
## Bosses share the fighter interface the game uses: box(), center(), take_hit(), dead, team.

const Part := preload("res://scripts/part.gd")
const OL := Color("1b1430")
const U := 180.0

var main
var kind := "serpent"
var team := "foe"
var hp := 500.0
var max_hp := 500.0
var dead := false
var face := -1
var st := "float"
var st_t := 0.0
var t := 0.0
var flash := 0.0
var arena_l := 0.0
var arena_r := 1280.0
var trail: Array = []
var target := Vector2.ZERO
var hitset := {}
var dead_t := 0.0
var swoop_dir := 1
var name_text := ""

func setup(m, k: String, l: float, r: float) -> void:
	main = m
	kind = k
	arena_l = l
	arena_r = r
	z_index = 3
	if kind == "serpent":
		hp = 520.0
		name_text = "SERPENT OF LIES"
		position = Vector2(r - 200, 420)
	else:
		hp = 1500.0
		name_text = "SATAN"
		position = Vector2((l + r) / 2, 230)
	max_hp = hp

func box() -> Rect2:
	if kind == "serpent":
		return Rect2(position - Vector2(40, 30), Vector2(80, 60))
	return Rect2(position + Vector2(-60, -20), Vector2(120, 200))

func center() -> Vector2:
	return box().get_center()

func take_hit(dmg: float, _dir: int, _kb: float, _up: float) -> bool:
	if dead:
		return false
	hp -= dmg
	flash = 1.0
	if hp <= 0.0:
		hp = 0.0
		dead = true
		main.on_boss_down(self)
	return true

func _physics_process(d: float) -> void:
	t += d
	flash = maxf(0.0, flash - d * 6.0)
	if dead:
		dead_t += d
		if int(dead_t * 20) % 3 == 0:
			main.spark(box().position + Vector2(randf() * box().size.x, randf() * box().size.y), Color(1, 0.95, 0.6))
		modulate.a = maxf(0.0, 1.0 - dead_t / 2.0)
		queue_redraw()
		return
	if main.frozen(self):
		queue_redraw()
		return
	st_t += d
	var rage := hp < max_hp * 0.5
	var p = main.nearest_enemy(center(), "foe", 3000.0)
	var pp: Vector2 = p.center() if p else Vector2((arena_l + arena_r) / 2, 560)
	if kind == "serpent":
		_serpent(d, rage, pp)
	else:
		_satan(d, rage, pp)
	queue_redraw()

func _serpent(d: float, rage: bool, pp: Vector2) -> void:
	var mid := (arena_l + arena_r) / 2
	var half := (arena_r - arena_l) / 2 - 140
	match st:
		"float":
			target = Vector2(mid + sin(t * 0.7) * half, 380 + sin(t * 1.8) * 150)
			if fmod(st_t, 1.6 if rage else 2.3) < d:
				for i in [-1, 0, 1]:
					var a: float = (pp - position).angle() + i * 0.25
					main.shoot(self, "venom", position, Vector2.from_angle(a) * 470.0, 8.0, 50.0)
			if st_t > (4.0 if rage else 5.5):
				st = "lunge"
				st_t = 0.0
				target = Vector2(pp.x, minf(pp.y, 560))
		"lunge":
			if st_t > 0.8:
				st = "rest"
				st_t = 0.0
				target = Vector2(position.x, 600)
		"rest":
			if st_t > (1.2 if rage else 1.8):
				st = "float"
				st_t = 0.0
	var k := 0.12 if st == "lunge" else 0.045
	var old := position
	position = position.lerp(target, 1.0 - pow(1.0 - k, d * 60.0))
	if absf(position.x - old.x) > 0.5:
		face = 1 if position.x > old.x else -1
	trail.push_front(position)
	if trail.size() > 90:
		trail.pop_back()
	# the head and body hurt on touch
	for h in main.heroes():
		if h.dead:
			continue
		var hb: Rect2 = h.box()
		if hb.intersects(box()):
			main.hurt_hero(h, 10.0, 1 if h.position.x > position.x else -1, 4.0, 3.0)
		else:
			for i in range(10, trail.size(), 10):
				var s: Vector2 = trail[i]
				if hb.intersects(Rect2(s - Vector2(18, 18), Vector2(36, 36))):
					main.hurt_hero(h, 8.0, 1 if h.position.x > s.x else -1, 3.0, 3.0)
					break

func _satan(d: float, rage: bool, pp: Vector2) -> void:
	var mid := (arena_l + arena_r) / 2
	var half := (arena_r - arena_l) / 2 - 200
	var k := 0.05
	match st:
		"float":
			target = Vector2(mid + sin(t * 0.6) * half, 170 + sin(t * 2.2) * 30)
			if fmod(st_t, 1.0 if rage else 1.5) < d:
				var n := 7 if rage else 5
				for i in n:
					var a: float = (pp - position - Vector2(0, 90)).angle() + (i - (n - 1) / 2.0) * 0.2
					main.shoot(self, "fire", position + Vector2(0, 90), Vector2.from_angle(a) * 430.0, 10.0, 55.0)
			if st_t > (4.5 if rage else 6.0):
				st_t = 0.0
				var opts := ["pillars", "swoop"]
				if main.foe_count() < 3:
					opts.append("summon")
				st = opts[randi() % opts.size()]
				if st == "swoop":
					swoop_dir = 1 if pp.x < mid else -1
					target = Vector2(arena_l + 120 if swoop_dir > 0 else arena_r - 120, 420)
				elif st == "pillars":
					for h in main.heroes().slice(0, 5):
						main.fire_pillar(h.position.x)
					main.fire_pillar(arena_l + 100 + randf() * (arena_r - arena_l - 200))
				elif st == "summon":
					main.spawn_foe("m", Vector2(arena_l + 80, 300))
					main.spawn_foe("m", Vector2(arena_r - 80, 300))
					if rage:
						main.spawn_foe("t", Vector2(mid, 200))
		"pillars", "summon":
			target = Vector2(mid, 120)
			if st_t > 2.0:
				st = "float"
				st_t = 0.0
		"swoop":
			if st_t > 0.9:
				k = 1.0
				target = Vector2(position.x + swoop_dir * (12.0 if rage else 9.0) * 60.0 * d, 420)
				if position.x < arena_l + 60 or position.x > arena_r - 60:
					st = "rest"
					st_t = 0.0
		"rest":
			target = Vector2(position.x, 420)
			if st_t > (1.4 if rage else 2.0):
				st = "float"
				st_t = 0.0
	position = position.lerp(target, 1.0 - pow(1.0 - k, d * 60.0)) if k < 1.0 else target
	face = 1 if pp.x > position.x else -1
	for h in main.heroes():
		if not h.dead and h.box().intersects(box()):
			main.hurt_hero(h, 14.0, 1 if h.position.x > position.x else -1, 5.0, 4.0)

func _draw() -> void:
	var g := Part.glow_tex()
	if kind == "serpent":
		for i in range(trail.size() - 1, 3, -4):
			var s: Vector2 = trail[i] - position
			var r := maxf(10.0, 28.0 - i * 0.2)
			draw_circle(s, r + 3, OL)
			draw_circle(s, r, Color("3d2a52") if (i / 4) % 2 == 0 else Color("5a3a72"))
			draw_circle(s + Vector2(0, r * 0.4), r * 0.5, Color("8a6aa0"))
		draw_texture_rect(g, Rect2(-70, -70, 140, 140), false, Color(0.6, 0.3, 0.86, 0.35))
		draw_set_transform(Vector2.ZERO, 0, Vector2(face * 3.2, 3.2))
		draw_colored_polygon(Part.ell_pts(Vector2.ZERO, 12.8, 8.8), OL)
		draw_colored_polygon(Part.ell_pts(Vector2.ZERO, 12, 8), Color("4a2a62").lerp(Color.WHITE, flash * 0.7))
		draw_colored_polygon(Part.ell_pts(Vector2(2, -2.5), 8, 3.6), Color("7a4f9a"))
		draw_colored_polygon(Part.ell_pts(Vector2(4.5, -3), 2, 1.6), Color("ffe04a"))
		draw_rect(Rect2(4.2, -4.4, 0.8, 2.8), Color("111111"))
		if sin(t * 18.0) > 0:
			draw_polyline(PackedVector2Array([Vector2(11, 2), Vector2(16, 2), Vector2(18, 0)]), Color("ff4b5c"), 1, true)
			draw_line(Vector2(16, 2), Vector2(18, 4), Color("ff4b5c"), 1, true)
		draw_set_transform(Vector2.ZERO)
		if st == "rest":
			_label("HIT IT!", Vector2(0, -90))
		return
	# Satan: wings, robe, horns and glowing eyes
	var fl := sin(t * 7.0) * 18.0
	draw_texture_rect(g, Rect2(-260, -140, 520, 520), false, Color(0.8, 0.1, 0.15, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2(3, 3))
	for m in [-1.0, 1.0]:
		var w := PackedVector2Array([Vector2(m * 8, 14), Vector2(m * 40, -4 + fl / 3), Vector2(m * 34, 8 + fl / 3), Vector2(m * 46, 20 + fl / 3), Vector2(m * 30, 24 + fl / 3), Vector2(m * 36, 34 + fl / 3), Vector2(m * 10, 30)])
		draw_colored_polygon(w, Color("2a0a18"))
		w.append(w[0])
		draw_polyline(w, Color("4a1426"), 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 12), Vector2(12, 12), Vector2(19, 60), Vector2(-19, 60)]), Color("5a1424").lerp(Color.WHITE, flash * 0.6))
	for i in 6:
		var x := -18 + i * 6
		draw_colored_polygon(PackedVector2Array([Vector2(x, 58), Vector2(x + 3, 63 + sin(t * 12 + i) * 2), Vector2(x + 6, 58)]), Color("8a1a30"))
	draw_line(Vector2(-10, 16), Vector2(-20, 30 + sin(t * 6) * 3), Color("3a0a18"), 4, true)
	draw_line(Vector2(10, 16), Vector2(20, 30 - sin(t * 6) * 3), Color("3a0a18"), 4, true)
	draw_circle(Vector2(0, 5), 9.8, OL)
	draw_circle(Vector2(0, 5), 9, Color("3a0a18").lerp(Color.WHITE, flash * 0.6))
	for m in [-1.0, 1.0]:
		var h := PackedVector2Array([Vector2(m * 6, -1)])
		h.append_array(Part.quad(Vector2(m * 6, -1), Vector2(m * 13, -6), Vector2(m * 12, -15)))
		h.append_array(Part.quad(Vector2(m * 12, -15), Vector2(m * 8, -6), Vector2(m * 2, -4)))
		draw_colored_polygon(h, Color("e8d8b8"))
	draw_texture_rect(g, Rect2(-12, -7, 24, 24), false, Color(1, 0.24, 0.24, 0.7))
	draw_colored_polygon(Part.ell_pts(Vector2(-3.5, 4), 2.4, 1.2, 0.3), Color("ff4040"))
	draw_colored_polygon(Part.ell_pts(Vector2(3.5, 4), 2.4, 1.2, -0.3), Color("ff4040"))
	draw_set_transform(Vector2.ZERO)
	if st == "rest":
		_label("ATTACK!", Vector2(0, -60))

func _label(s: String, p: Vector2) -> void:
	if int(t * 4) % 2 == 0:
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string_outline(f, p - Vector2(w / 2, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, OL)
		draw_string(f, p - Vector2(w / 2, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffd25a"))
