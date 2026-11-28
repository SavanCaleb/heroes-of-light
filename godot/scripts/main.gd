extends Node2D
## Heroes of Light (Godot) - first playable slice: the Garden of Hope.
## Run with `-- demo` to let the hero play itself (used for capturing test frames),
## and `-- hero=N` (0-7) to pick a hero.

const Data := preload("res://scripts/data.gd")
const Level := preload("res://scripts/level.gd")
const Fighter := preload("res://scripts/fighter.gd")
const Rig := preload("res://scripts/rig.gd")
const Backdrop := preload("res://scripts/backdrop.gd")
const Fx := preload("res://scripts/fx.gd")
const T := Data.T

const MINION_DEF := {name="Shadow", hp=30, spd=0.76, jmp=6.0, look=Data.MINION}

var level
var player
var foes: Array = []
var coins: Array = []
var candles: Array = []
var goal: Node2D
var camera: Camera2D
var hud
var hitstop := 0.0
var shake := 0.0
var coins_n := 0
var freed := 0
var combo := 0
var combo_t := 0.0
var best_combo := 0
var respawn := Vector2.ZERO
var finished := false
var demo := false
var hero_i := 3
var _demo_t := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "demo":
			demo = true
		elif a.begins_with("hero="):
			hero_i = clampi(int(a.substr(5)), 0, 7)
	_inputs()
	level = Level.new()
	level.build(Data.LEVELS[0])
	Backdrop.build(self, level.width_px)
	add_child(level)
	var hero_def: Dictionary = Data.HEROES[hero_i]
	var npc_i := 0
	for o in level.objs:
		var p: Vector2 = o.pos
		match o.t:
			"P":
				respawn = p + Vector2(T / 2, T)
			"o":
				var c := Fx.Coin.new()
				c.position = p + Vector2(T / 2, T / 2)
				c.z_index = 1
				add_child(c)
				coins.append(c)
			"m", "t", "e", "j":
				_spawn_foe(Vector2(p.x + T / 2, level.ground_below(p.x + T / 2, p.y)))
			"n":
				var id: String = Data.LEVELS[0].npcs[mini(npc_i, Data.LEVELS[0].npcs.size() - 1)]
				npc_i += 1
				_spawn_npc(id, Vector2(p.x + T / 2, level.ground_below(p.x + T / 2, p.y)))
			"G":
				goal = Fx.Goal.new()
				goal.position = Vector2(p.x + T / 2, level.ground_below(p.x + T / 2, p.y))
				goal.z_index = 1
				add_child(goal)
			"c":
				var cd := Fx.Candle.new()
				cd.position = Vector2(p.x + T / 2, level.ground_below(p.x + T / 2, p.y))
				cd.z_index = 1
				add_child(cd)
				candles.append(cd)
	player = Fighter.new()
	player.setup(self, hero_def, false, "hero")
	player.position = respawn
	player.z_index = 3
	add_child(player)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = int(level.width_px)
	camera.limit_top = 0
	camera.limit_bottom = int(Data.ROWS * T)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.position = Vector2(player.position.x, 360)
	add_child(camera)
	_ambient_particles()
	hud = Hud.new()
	hud.main = self
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	layer.add_child(hud)

func _inputs() -> void:
	var map := {
		left=[KEY_LEFT, KEY_A], right=[KEY_RIGHT, KEY_D], jump=[KEY_SPACE, KEY_UP, KEY_W, KEY_Z],
		attack=[KEY_J, KEY_X, KEY_F],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)

func _spawn_foe(pos: Vector2) -> void:
	var f := Fighter.new()
	f.setup(self, MINION_DEF, true, "foe")
	f.position = pos
	f.face = -1
	f.z_index = 2
	add_child(f)
	foes.append(f)

func _spawn_npc(id: String, pos: Vector2) -> void:
	var n: Dictionary = Data.NPCS[id]
	var r := Rig.new()
	r.setup(n.look)
	r.position = pos
	r.face = -1
	r.z_index = 2
	add_child(r)
	var lbl := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 18
	ls.font_color = Color("ffe9a8")
	ls.outline_size = 6
	ls.outline_color = Color("1b1430")
	lbl.label_settings = ls
	lbl.text = n.name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(200, 24)
	lbl.position = pos + Vector2(-100, -150)
	lbl.z_index = 4
	add_child(lbl)

func _ambient_particles() -> void:
	# floating pollen and drifting petals that follow the camera
	var pollen := CPUParticles2D.new()
	pollen.amount = 46
	pollen.lifetime = 9.0
	pollen.preprocess = 9.0
	pollen.texture = preload("res://scripts/part.gd").glow_tex()
	pollen.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pollen.emission_rect_extents = Vector2(900, 420)
	pollen.direction = Vector2(-1, -0.3)
	pollen.spread = 60
	pollen.initial_velocity_min = 8
	pollen.initial_velocity_max = 26
	pollen.gravity = Vector2(0, -4)
	pollen.scale_amount_min = 0.04
	pollen.scale_amount_max = 0.1
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.96, 0.75, 0))
	g.add_point(0.3, Color(1, 0.96, 0.75, 0.75))
	g.set_color(1, Color(1, 0.96, 0.75, 0))
	pollen.color_ramp = g
	pollen.material = Fx.additive()
	pollen.z_index = 9
	camera.add_child(pollen)
	var petals := CPUParticles2D.new()
	petals.amount = 16
	petals.lifetime = 12.0
	petals.preprocess = 12.0
	petals.texture = pollen.texture
	petals.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(900, 10)
	petals.position = Vector2(0, -420)
	petals.direction = Vector2(-1, 0.4)
	petals.spread = 30
	petals.initial_velocity_min = 30
	petals.initial_velocity_max = 60
	petals.gravity = Vector2(0, 14)
	petals.scale_amount_min = 0.07
	petals.scale_amount_max = 0.11
	petals.color = Color(1, 0.62, 0.78, 0.9)
	petals.z_index = 9
	camera.add_child(petals)

# ---------------- per-frame ----------------
func _physics_process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop -= delta
		return
	_player_input(delta)
	# camera: lead ahead of the hero, with screen shake
	camera.position = Vector2(player.position.x + player.face * 110.0, 360)
	if shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
		shake = maxf(0.0, shake - delta * 60.0)
	else:
		camera.offset = Vector2.ZERO
	# coins
	var pc: Vector2 = player.center()
	for c in coins.duplicate():
		if not is_instance_valid(c):
			coins.erase(c)
			continue
		if c.loose:
			c.vel.y += 1800.0 * delta
			c.position += c.vel * delta
			if c.vel.y > 0 and level.solid(int(c.position.x / T), int((c.position.y + 16) / T)):
				c.position.y = int((c.position.y + 16) / T) * T - 16
				c.vel.y = -c.vel.y * 0.4 if absf(c.vel.y) > 200 else 0.0
				c.vel.x *= 0.7
		var d := pc.distance_to(c.position)
		if d < 120.0 and (not c.loose or c.age > 0.35):
			c.position = c.position.lerp(pc, 0.25)
			c.loose = true
			c.vel = Vector2.ZERO
		if d < 34.0:
			coins.erase(c)
			coins_n += 1
			Fx.burst(self, c.position, Color("ffe27a"), 8, 260, 0.06)
			c.queue_free()
	# checkpoints
	for cd in candles:
		if not cd.lit and absf(player.position.x - cd.position.x) < 40:
			cd.lit = true
			respawn = cd.position + Vector2(-30, 0)
			Fx.burst(self, cd.position + Vector2(0, -50), Color("ffb040"), 20, 300, 0.08)
			cd.queue_redraw()
	# fell into a pit
	if player.position.y > Data.ROWS * T + 120:
		player.position = respawn
		player.velocity = Vector2.ZERO
		player.hp = maxf(1.0, player.hp - 20.0)
		player.inv = 90.0
		combo = 0
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo = 0
	# goal
	if goal and not finished and absf(player.position.x - goal.position.x) < 50:
		finished = true
		player.rig.pose = "cheer"
		Fx.burst(self, goal.position + Vector2(0, -80), Color("ffe27a"), 60, 700, 0.12)
		hud.banner("LAND RESTORED!")

func _player_input(delta: float) -> void:
	var inp: Dictionary = player.input
	if finished:
		inp.dir = 0
		inp.jump_p = false
		inp.jump_h = false
		inp.atk_p = false
		return
	if demo:
		_demo_input(delta)
		return
	inp.dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	inp.jump_p = Input.is_action_just_pressed("jump")
	inp.jump_h = Input.is_action_pressed("jump")
	inp.atk_p = Input.is_action_just_pressed("attack")

func _demo_input(delta: float) -> void:
	## Autopilot: run right, hop over gaps and walls, fight any shadow ahead.
	_demo_t += delta
	var inp: Dictionary = player.input
	var p: Vector2 = player.position
	inp.dir = 1
	inp.atk_p = false
	inp.jump_p = false
	var near = null
	for f in foes:
		if is_instance_valid(f) and not f.dead and absf(f.position.x - p.x) < 130 and absf(f.position.y - p.y) < 90:
			near = f
	if near:
		inp.dir = 1 if near.position.x > p.x + 40 else (-1 if near.position.x < p.x - 40 else 0)
		player.face = 1 if near.position.x > p.x else -1
		inp.atk_p = fmod(_demo_t, 0.2) < delta * 1.5
	var c := int((p.x + 40) / T)
	var r := int((p.y + 8) / T)
	if player.is_on_floor() and (player.is_on_wall() or not level.solid(c, r) or level.solid(c, r - 1)):
		inp.jump_p = true
	inp.jump_h = not player.is_on_floor()

# ---------------- combat callbacks ----------------
func strike(attacker, rect: Rect2, dmg: float, kb: float, up: float) -> void:
	var targets: Array = foes if attacker.team == "hero" else [player]
	for t in targets:
		if not is_instance_valid(t) or t.dead or attacker.hitset.has(t):
			continue
		if rect.intersects(t.box()):
			attacker.hitset[t] = true
			var dir := 1 if t.position.x >= rect.get_center().x else -1
			if t.take_hit(dmg, dir, kb, up):
				var hit_at: Vector2 = rect.intersection(t.box()).get_center()
				var s := Fx.Spark.new()
				s.position = hit_at
				s.gold = attacker.team == "hero"
				add_child(s)
				var big := dmg >= 12.0
				var n := Fx.Number.new()
				n.setup(str(int(round(dmg))), Color("ffd25a") if big else Color.WHITE, big)
				n.position = hit_at + Vector2(randf_range(-10, 10), -30)
				add_child(n)
				hitstop = 0.07 if big else 0.045
				shake = 9.0 if big else 4.0
				if attacker.team == "hero":
					combo += 1
					combo_t = 2.4
					best_combo = maxi(best_combo, combo)
				else:
					shake = 12.0
					combo = 0

func on_defeat(f) -> void:
	if f == player:
		player.dead = false
		player.hp = player.max_hp
		player.position = respawn
		player.inv = 120.0
		return
	freed += 1
	var c: Vector2 = f.center()
	Fx.burst(self, c, Color("c9b6ff"), 26, 520, 0.12)
	var dv := Fx.Dove.new()
	dv.position = c
	dv.z_index = 8
	add_child(dv)
	for i in 3 + mini(4, combo / 6):
		var coin := Fx.Coin.new()
		coin.position = c
		coin.loose = true
		coin.vel = Vector2(randf_range(-260, 260), randf_range(-700, -420))
		coin.z_index = 4
		add_child(coin)
		coins.append(coin)
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.35)
	tw.tween_callback(f.queue_free)
	foes.erase(f)

func on_jump(f) -> void:
	Fx.dust(self, f.position, 5, 0.8)

func on_double_jump(f) -> void:
	Fx.burst(self, f.position + Vector2(0, -4), Color.WHITE, 10, 220, 0.07)

func on_land(f, v: float) -> void:
	Fx.dust(self, f.position, 10, 1.0 + v / 2000.0)
	if f == player and v > 1100.0:
		shake = maxf(shake, 3.0)

func on_step(f) -> void:
	Fx.dust(self, f.position + Vector2(-f.face * 10, 0), 2, 0.5)

func on_swing(_f) -> void:
	pass

# ---------------- HUD ----------------
class Hud extends Control:
	var main
	var banner_text := ""
	var banner_t := 0.0
	var font: Font
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		font = ThemeDB.fallback_font
	func banner(s: String) -> void:
		banner_text = s
		banner_t = 0.0
	func _process(d: float) -> void:
		banner_t += d
		queue_redraw()
	func _bar(r: Rect2, v: float, c1: Color, c2: Color) -> void:
		draw_rect(r, Color(0, 0, 0, 0.5))
		if v > 0.0:
			var w := r.size.x * clampf(v, 0, 1)
			draw_polygon(PackedVector2Array([r.position, r.position + Vector2(w, 0), r.position + Vector2(w, r.size.y), r.position + Vector2(0, r.size.y)]), PackedColorArray([c1, c1, c2, c2]))
			draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(maxf(0, w - 4), r.size.y * 0.28)), Color(1, 1, 1, 0.35))
	func _text(s: String, p: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
		draw_string_outline(font, p, s, align, w, size, 7, Color("1b1430"))
		draw_string(font, p, s, align, w, size, col)
	func _draw() -> void:
		var p = main.player
		if p == null:
			return
		var vw := get_viewport_rect().size.x
		draw_rect(Rect2(16, 16, 360, 92), Color(0.05, 0.04, 0.1, 0.72))
		draw_rect(Rect2(16, 16, 360, 92), Color(1, 0.82, 0.35, 0.45), false, 2.0)
		_text(p.def.name + "  " + p.def.title, Vector2(30, 46), 24, Color("ffd25a"))
		_bar(Rect2(30, 58, 330, 18), p.hp / p.max_hp, Color("ff8a9a"), Color("d8283a"))
		_text("%d / %d" % [int(p.hp), int(p.max_hp)], Vector2(30, 74), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 326)
		_bar(Rect2(30, 82, 330, 12), p.mp / 100.0, Color("9ad8ff"), Color("2a78d8"))
		draw_rect(Rect2(vw - 210, 16, 194, 50), Color(0.05, 0.04, 0.1, 0.72))
		draw_circle(Vector2(vw - 186, 41), 13, Color("1b1430"))
		draw_circle(Vector2(vw - 186, 41), 10.5, Color("ffc93a"))
		draw_rect(Rect2(vw - 187.5, 34, 3, 14), Color("b0640a"))
		_text(str(main.coins_n), Vector2(vw - 164, 51), 28, Color("ffe27a"))
		_text("freed " + str(main.freed), Vector2(vw - 100, 51), 18, Color("e8e0ff"))
		var lw: float = main.level.width_px
		var prog := clampf(p.position.x / maxf(1.0, lw - 60.0), 0, 1)
		var bx := vw * 0.5 - 180
		_text(Data.LEVELS[0].name, Vector2(bx, 36), 20, Color("fff6d8"), HORIZONTAL_ALIGNMENT_CENTER, 360)
		_bar(Rect2(bx, 46, 360, 10), prog, Color("ffe27a"), Color("ffb020"))
		draw_circle(Vector2(bx + 360 * prog, 51), 11, Color("1b1430"))
		draw_circle(Vector2(bx + 360 * prog, 51), 8, Color(String(p.def.look.shirt)))
		if main.combo >= 2:
			var k := 1.0 + clampf(main.combo_t - 2.2, 0, 0.2) * 1.5
			draw_set_transform(Vector2(vw - 120, 150), -0.08, Vector2(k, k))
			_text(str(main.combo), Vector2(-80, 0), 64, Color("ffe27a"), HORIZONTAL_ALIGNMENT_CENTER, 160)
			_text("HITS", Vector2(-80, 30), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 160)
			draw_set_transform(Vector2.ZERO)
		if banner_text != "":
			var a := clampf(banner_t * 3.0, 0, 1)
			var vh := get_viewport_rect().size.y
			draw_rect(Rect2(0, vh * 0.36, vw, 120), Color(0.05, 0.04, 0.1, 0.6 * a))
			_text(banner_text, Vector2(0, vh * 0.36 + 82), int(64 * (0.6 + 0.4 * a)), Color("ffd25a"), HORIZONTAL_ALIGNMENT_CENTER, vw)
