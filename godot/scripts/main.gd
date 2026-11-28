extends Node2D
## One land of Heroes of Light: builds it, runs the fight, the friends you meet,
## BATTLE zones, the boss, the SUPER cinematic and the results.

const Data := preload("res://scripts/data.gd")
const Level := preload("res://scripts/level.gd")
const Fighter := preload("res://scripts/fighter.gd")
const Rig := preload("res://scripts/rig.gd")
const Backdrop := preload("res://scripts/backdrop.gd")
const Fx := preload("res://scripts/fx.gd")
const Combat := preload("res://scripts/combat.gd")
const Boss := preload("res://scripts/boss.gd")
const Hud := preload("res://scripts/hud.gd")
const Touch := preload("res://scripts/touch.gd")
const T := Data.T
const U := 180.0
const SKILL_COST := 30.0

var L: Dictionary
var level
var player
var camera: Camera2D
var hud
var touch
var foes: Array = []
var allies: Array = []
var coins: Array = []
var candles: Array = []
var npcs: Array = []
var zones: Array = []
var arena = null
var boss = null
var goal: Node2D
var lock = null
var walls: StaticBody2D
var wave_label := ""

var mode := "play"           # play, dialog, super, grace, results
var dialog := {}
var sup := {}
var result := {}
var result_t := 0.0
var grace_t := 0.0
var flash := 0.0
var hitstop := 0.0
var shake := 0.0
var zoom := 1.0
var zoom_kick := 0.0
var slowmo := 0.0

var coins_n := 0
var coins_static := 0
var coins_max := 0
var freed := 0
var falls := 0
var combo := 0
var combo_t := 0.0
var best_combo := 0
var respawn := Vector2.ZERO
var angel_used := false
var finished := false

var tut: Array = []
var tut_i := 99
var flags := {}
var _demo_t := 0.0

func _ready() -> void:
	L = Data.LEVELS[Game.level_i]
	Engine.time_scale = 1.0
	level = Level.new()
	level.build(L)
	Backdrop.build(self, level.width_px, L.theme)
	add_child(level)
	var npc_i := 0
	for o in level.objs:
		var p: Vector2 = o.pos
		var ground := Vector2(p.x + T / 2, level.ground_below(p.x + T / 2, p.y))
		match o.t:
			"P":
				respawn = p + Vector2(T / 2, T)
			"o", "h", "s":
				_coin(p + Vector2(T / 2, T / 2), false)
				coins_max += 1
			"m", "e", "j", "f":
				spawn_foe("m", ground)
			"t":
				spawn_foe("t", ground)
			"b":
				spawn_foe("b", ground)
			"n":
				var id: String = L.npcs[mini(npc_i, L.npcs.size() - 1)]
				npc_i += 1
				_npc(id, ground)
			"G":
				goal = Fx.Goal.new()
				goal.position = ground
				goal.z_index = 1
				add_child(goal)
			"c":
				var cd := Fx.Candle.new()
				cd.position = ground
				cd.z_index = 1
				add_child(cd)
				candles.append(cd)
			"W":
				zones.append({x=p.x, wave=-1, active=false, done=false})
			"B":
				arena = {x=p.x, started=false}
	var extra := {}
	if Game.own("cape") > 0:
		extra.cape = true
	if Game.own("halo") > 0:
		extra.halo = true
	player = Fighter.new()
	player.setup(self, Game.hero_def(), false, "hero", "hero", extra)
	if "atbattle" in OS.get_cmdline_user_args() and zones.size() > 0:
		respawn = Vector2(zones[0].x + 100, 300)
	if "atboss" in OS.get_cmdline_user_args() and arena:
		respawn = Vector2(arena.x + 120, 300)
	if "glory" in OS.get_cmdline_user_args():
		player.glory = 100.0
	player.position = respawn
	player.z_index = 4
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
	Backdrop.particles(camera, L.theme)
	var hl := CanvasLayer.new()
	hl.layer = 10
	hl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hl)
	hud = Hud.new()
	hud.main = self
	hl.add_child(hud)
	if Game.touch:
		var tl := CanvasLayer.new()
		tl.layer = 11
		tl.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(tl)
		touch = Touch.new()
		touch.main = self
		tl.add_child(touch)
	if Game.level_i == 0:
		_setup_tutorial()
	Game.music(land_music())
	var intro: Array = L.story
	if Game.demo:
		hud.banner(L.name.to_upper(), L.goal)
	else:
		say(intro, func(): hud.banner(L.name.to_upper(), L.goal))

# ---------------- spawning ----------------
func _coin(pos: Vector2, loose: bool, vel := Vector2.ZERO) -> void:
	var c := Fx.Coin.new()
	c.position = pos
	c.loose = loose
	c.vel = vel
	c.z_index = 2
	c.set_meta("static", not loose)
	add_child(c)
	coins.append(c)

func spawn_foe(k: String, pos: Vector2):
	var f := Fighter.new()
	var d := {name="Shadow", hp=30 + Game.level_i * 6, spd=0.8 + Game.level_i * 0.04, jmp=6.0, look=Data.MINION}
	if k == "t":
		d = {name="Shadow Thrower", hp=26 + Game.level_i * 5, spd=0.7, jmp=6.0, look=Data.THROWER}
	elif k == "b":
		d = {name="Shadow Brute", hp=90 + Game.level_i * 12, spd=0.55, jmp=5.0, look=Data.BRUTE, dmg=1.0}
	elif k == "giant":
		d = {name="Giant of Fear", hp=480, spd=0.7, jmp=8.5, look=Data.GIANT}
	f.setup(self, d, true, "foe", k)
	f.position = pos
	f.face = -1
	f.z_index = 3
	add_child(f)
	foes.append(f)
	return f

func _npc(id: String, pos: Vector2) -> void:
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
	lbl.size = Vector2(240, 24)
	lbl.position = pos + Vector2(-120, -160)
	lbl.z_index = 4
	add_child(lbl)
	var bubble := Fx.Bubble.new()
	bubble.position = pos + Vector2(0, -180)
	bubble.z_index = 4
	add_child(bubble)
	npcs.append({id=id, rig=r, x=pos.x, talked=false, bubble=bubble})

# ---------------- state helpers used by fighters, bosses and effects ----------------
func frozen(_who) -> bool:
	return hitstop > 0.0 or mode != "play" or finished

func power_pose(f) -> bool:
	return mode == "super" and f == player

func heroes() -> Array:
	var h: Array = []
	if player and not player.dead:
		h.append(player)
	for a in allies:
		if is_instance_valid(a) and not a.dead:
			h.append(a)
	return h

func foe_count() -> int:
	var n := 0
	for f in foes:
		if is_instance_valid(f) and not f.dead and f.get_script() == Fighter:
			n += 1
	return n

func nearest_enemy(pos: Vector2, team: String, rng: float):
	var list: Array = foes if team == "hero" else heroes()
	var best = null
	var bd := rng
	for f in list:
		if not is_instance_valid(f) or f.dead:
			continue
		var d: float = pos.distance_to(f.center())
		if d < bd:
			bd = d
			best = f
	return best

func land_music() -> String:
	return ["land1", "land2", "land3"][Game.level_i % 3]

func boss_name() -> String:
	match L.get("boss", ""):
		"giant": return "Giant of Fear"
		"serpent": return "Serpent of Lies"
		"satan": return "Satan"
	return ""

func hero_screen_pos() -> Vector2:
	return get_viewport().get_canvas_transform() * player.center()

# ---------------- the main loop ----------------
func _physics_process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.01)
	if slowmo > 0.0:
		slowmo -= real
		if slowmo <= 0.0:
			Engine.time_scale = 1.0
	flash = maxf(0.0, flash - real * 2.5)
	zoom_kick = maxf(0.0, zoom_kick - real * 0.5)
	if hitstop > 0.0:
		hitstop -= real
	match mode:
		"dialog":
			_dialog_step(real)
		"super":
			_super_step(real)
		"grace":
			grace_t += real
			if (Game.demo and grace_t > 1.5) or (grace_t > 0.8 and (Input.is_action_just_pressed("ok") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump"))):
				_respawn()
		"results":
			result_t += real
			if Input.is_action_just_pressed("ok") and result_t > 1.8:
				on_button("nextland" if Game.level_i + 1 < Data.LEVELS.size() else "map")
	if Input.is_action_just_pressed("back") and mode == "play":
		toggle_pause()
	_player_input(delta)
	_camera(real)
	if mode != "play":
		return
	_coins(delta)
	_world_checks()
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			if combo >= 8:
				var b := combo / 4
				coins_n += b
				hud.toast("Combo bonus: +%d coins!" % b, 1.5)
			combo = 0
	_tutorial_check()

func _camera(real: float) -> void:
	var vw := get_viewport_rect().size.x
	var target_zoom := 1.0
	var target := Vector2(player.position.x + player.face * 110.0, 360)
	if lock:
		target.x = (lock.l + lock.r) / 2.0
	if mode == "super":
		target_zoom = 1.0 + 0.45 * clampf(sup.t * 3.0, 0, 1) * (1.0 - clampf((sup.t - 1.0) * 5.0, 0, 1))
		target = player.center()
	zoom = lerpf(zoom, target_zoom + zoom_kick, 1.0 - exp(-real * 10.0))
	camera.zoom = Vector2(zoom, zoom)
	camera.position = target
	if shake > 0.0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
		shake = maxf(0.0, shake - real * 60.0)
	else:
		camera.offset = Vector2.ZERO
	if lock:
		camera.limit_left = int(lock.l)
		camera.limit_right = int(lock.l + vw)
	else:
		camera.limit_left = 0
		camera.limit_right = int(level.width_px)

func _player_input(delta: float) -> void:
	var inp: Dictionary = player.input
	for k in ["jump_p", "atk_p", "skill_p", "super_p"]:
		inp[k] = false
	if mode != "play" or finished:
		inp.dir = 0
		inp.jump_h = false
		inp.block = false
		return
	if Game.demo:
		_demo_input(delta)
		return
	inp.dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	inp.jump_p = Input.is_action_just_pressed("jump")
	inp.jump_h = Input.is_action_pressed("jump")
	inp.atk_p = Input.is_action_just_pressed("attack")
	inp.skill_p = Input.is_action_just_pressed("skill")
	inp.super_p = Input.is_action_just_pressed("super")
	inp.block = Input.is_action_pressed("block")

func _demo_input(delta: float) -> void:
	## Autopilot for recording test frames: run right, hop gaps, fight, use skills and the SUPER.
	_demo_t += delta
	var inp: Dictionary = player.input
	var p: Vector2 = player.position
	inp.dir = 1
	inp.block = false
	var near = nearest_enemy(player.center(), "hero", 170.0)
	if near:
		var dx: float = near.center().x - player.center().x
		inp.dir = 0 if absf(dx) < 70 else (1 if dx > 0 else -1)
		player.face = 1 if dx > 0 else -1
		inp.atk_p = fmod(_demo_t, 0.16) < delta * 1.5
		if player.mp >= SKILL_COST and fmod(_demo_t, 3.0) < delta:
			inp.skill_p = true
		if player.glory >= 100.0:
			inp.super_p = true
	elif lock:
		inp.dir = 1 if p.x < (lock.l + lock.r) / 2 else -1
	var c := int((p.x + 40) / T)
	var r := int((p.y + 8) / T)
	if player.is_on_floor() and (player.is_on_wall() or not level.solid(c, r) or level.solid(c, r - 1)):
		inp.jump_p = true
	inp.jump_h = not player.is_on_floor()

func _coins(delta: float) -> void:
	var pc: Vector2 = player.center()
	var reach := 260.0 if Game.own("magnet") > 0 else 120.0
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
		if d < reach and (not c.loose or c.age > 0.35):
			c.position = c.position.lerp(pc, 0.25)
			c.loose = true
			c.vel = Vector2.ZERO
		if d < 34.0:
			coins.erase(c)
			coins_n += 1
			Game.sfx("coin")
			if c.get_meta("static", false):
				coins_static += 1
			Fx.burst(self, c.position, Color("ffe27a"), 8, 260, 0.06)
			c.queue_free()

func _world_checks() -> void:
	var px: float = player.position.x
	var vw := get_viewport_rect().size.x
	for cd in candles:
		if not cd.lit and absf(px - cd.position.x) < 40:
			cd.lit = true
			respawn = cd.position + Vector2(-30, 0)
			Fx.burst(self, cd.position + Vector2(0, -50), Color("ffb040"), 20, 300, 0.08)
			hud.toast("Checkpoint! The candle is lit.", 1.5)
	for n in npcs:
		if not n.talked and absf(px - n.x) < 70 and player.is_on_floor():
			n.talked = true
			n.bubble.queue_free()
			n.rig.pose = "cheer"
			var lines: Array = []
			for s in Data.TALK[n.id]:
				lines.append([n.id, String(s).replace("#NAME#", player.def.name)])
			say(lines, func():
				player.hp = player.max_hp
				player.mp = 100.0
				n.rig.pose = "idle"
				hud.toast("HP and energy fully restored!", 1.8))
			return
	for z in zones:
		if z.done:
			continue
		if not z.active and px > z.x + 260 and px < z.x + vw - 60:
			z.active = true
			_lock(z.x, z.x + vw)
			hud.banner("BATTLE!", "Defeat every shadow to move on")
			Game.music("battle")
			shake = 8.0
			_next_wave(z)
		elif z.active:
			z.t = z.get("t", 0.0) + get_physics_process_delta_time()
			if z.t > 20.0 and _wave_left() > 0:
				# safety net: bring any shadow that got stuck somewhere back to the fight
				z.t = 0.0
				for f in foes:
					if is_instance_valid(f) and not f.dead and f.has_meta("wave"):
						f.position = Vector2(_ground_x(player.position.x + randf_range(-200, 200)), 120)
						f.velocity = Vector2.ZERO
		if z.active and _wave_left() == 0:
			z.t = 0.0
			if z.wave + 1 < L.waves.size():
				_next_wave(z)
			else:
				z.done = true
				z.active = false
				_unlock()
				hud.banner("GO!", "The way is open  >>>")
				Game.music(land_music())
				_slowmo(0.5)
	if arena and not arena.started and px > arena.x + 300:
		arena.started = true
		_lock(arena.x, arena.x + vw)
		var talk: Array = L.get("boss_talk", [])
		say(talk, _spawn_boss)
	# shadows that fall out of the world are gone, so they can't keep a BATTLE zone locked
	for f in foes.duplicate():
		if is_instance_valid(f) and not f.dead and f.position.y > Data.ROWS * T + 100:
			on_defeat(f)
	if player.position.y > Data.ROWS * T + 120:
		falls += 1
		player.hp -= 25.0
		combo = 0
		if player.hp <= 0.0:
			on_defeat(player)
		else:
			_put_back()
	if goal and not finished and absf(px - goal.position.x) < 60 and not flags.has("outro"):
		flags.outro = true
		player.rig.pose = "cheer"
		say(L.outro, func(): _finish(false))

func _next_wave(z: Dictionary) -> void:
	z.wave += 1
	var list: Array = L.waves[z.wave]
	wave_label = "WAVE %d / %d" % [z.wave + 1, L.waves.size()]
	for i in list.size():
		var side := i % 2
		var x: float = lock.l + (120 if side == 0 else get_viewport_rect().size.x - 120) + randf_range(-40, 40)
		var f = spawn_foe(list[i], Vector2(_ground_x(x), 120))
		f.velocity.y = 200
		f.set_meta("wave", true)

## Shadows from the current BATTLE wave that are still standing (other shadows in the land don't count).
func _wave_left() -> int:
	var n := 0
	for f in foes:
		if is_instance_valid(f) and not f.dead and f.has_meta("wave"):
			n += 1
	return n

## Nearest x (moving toward the middle of the locked area) that has solid ground under it.
func _ground_x(x: float) -> float:
	var mid: float = (lock.l + lock.r) / 2.0 if lock else x
	var step := 24.0 if x < mid else -24.0
	for i in 80:
		if level.ground_below(x, 100) < Data.ROWS * T:
			return x
		x += step
	return mid

func _lock(l: float, r: float) -> void:
	lock = {l=l, r=r}
	walls = StaticBody2D.new()
	for x in [l - 20, r + 20]:
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 2000)
		sh.shape = rect
		sh.position = Vector2(x, 0)
		walls.add_child(sh)
	add_child(walls)

func _unlock() -> void:
	lock = null
	wave_label = ""
	if walls:
		walls.queue_free()
		walls = null

func _spawn_boss() -> void:
	var vw := get_viewport_rect().size.x
	match L.boss:
		"giant":
			boss = spawn_foe("giant", Vector2(lock.l + vw - 220, 200))
		"serpent", "satan":
			boss = Boss.new()
			boss.setup(self, L.boss, lock.l, lock.l + vw)
			add_child(boss)
			foes.append(boss)
	shake = 14.0
	hud.banner(boss_name().to_upper(), "Boss battle!")
	Game.music("boss")
	if L.boss == "satan":
		_spawn_allies()

func _spawn_allies() -> void:
	var defs: Array = []
	for h in Data.HEROES:
		if h.id != player.def.id:
			defs.append(h)
	defs.append(Data.BELINDA)
	for i in defs.size():
		var a := Fighter.new()
		a.setup(self, defs[i], true, "hero", "ally")
		a.position = Vector2(lock.l + 80 + i * 70, 100 - i * 30)
		a.face = 1
		a.z_index = 3
		add_child(a)
		allies.append(a)
		Fx.burst(self, a.position + Vector2(0, -60), Color(1, 0.95, 0.7), 14, 300, 0.08)

# ---------------- combat ----------------
func strike(attacker, rect: Rect2, dmg: float, kb: float, up: float, hitset: Dictionary) -> bool:
	return _hit(attacker.team, rect, dmg, kb, up, hitset, attacker)

func strike_box(proj, rect: Rect2, dmg: float, kb: float, up: float) -> bool:
	return _hit(proj.team, rect, dmg, kb, up, proj.hitset, null)

func _hit(team: String, rect: Rect2, dmg: float, kb: float, up: float, hitset: Dictionary, attacker) -> bool:
	var targets: Array = foes if team == "hero" else heroes()
	var any := false
	for t in targets:
		if not is_instance_valid(t) or t.dead or hitset.has(t):
			continue
		if not rect.intersects(t.box()):
			continue
		hitset[t] = true
		var dir := 1 if t.center().x >= rect.get_center().x else -1
		if attacker and "face" in attacker:
			dir = attacker.face
		if t.take_hit(dmg, dir, kb, up):
			any = true
			_hit_fx(rect.intersection(t.box()).get_center(), dmg, team, attacker)
	return any

func _hit_fx(at: Vector2, dmg: float, team: String, attacker) -> void:
	var big := dmg >= 12.0
	var s := Fx.Spark.new()
	s.position = at
	s.gold = team == "hero"
	add_child(s)
	var n := Fx.Number.new()
	n.setup(str(int(round(dmg))), Color("ffd25a") if big else Color.WHITE, big)
	n.position = at + Vector2(randf_range(-12, 12), -34)
	add_child(n)
	hitstop = maxf(hitstop, 0.085 if big else 0.045)
	Game.sfx("big" if big else "hit")
	shake = maxf(shake, 10.0 if big else 4.0)
	if big:
		zoom_kick = 0.05
	if team == "hero":
		combo += 1
		combo_t = 2.4
		best_combo = maxi(best_combo, combo)
		if attacker == player or attacker == null:
			player.glory = minf(100.0, player.glory + dmg * 0.55 * (1.0 + Game.own("zeal") * 0.3))
	else:
		shake = 12.0
		combo = 0

func ring_hit(ring) -> void:
	var targets: Array = foes if ring.team == "hero" else heroes()
	for t in targets:
		if not is_instance_valid(t) or t.dead or ring.hitset.has(t):
			continue
		var c: Vector2 = t.center()
		var dv: Vector2 = c - ring.position
		if ring.flat and absf(dv.y) > 90:
			continue
		if dv.length() < ring.r + 24:
			ring.hitset[t] = true
			if t.take_hit(ring.dmg, 1 if dv.x >= 0 else -1, ring.kb, ring.up):
				_hit_fx(c, ring.dmg, ring.team, null)

func hurt_hero(h, dmg: float, dir: int, kb: float, up: float) -> void:
	if h.take_hit(dmg, dir, kb, up):
		_hit_fx(h.center(), dmg, "foe", null)

func spark(pos: Vector2, col: Color) -> void:
	Fx.burst(self, pos, col, 8, 240, 0.07)

func shoot(src, kind: String, pos: Vector2, vel: Vector2, dmg: float, _x := 0.0) -> void:
	var p := Combat.Proj.new()
	p.main = self
	p.kind = kind
	p.team = src.team
	p.position = pos
	p.vel = vel
	p.dmg = dmg
	p.life = 4.0
	p.col = Color("ff7a2a") if kind == "fire" else Color("9aff6a")
	add_child(p)

func foe_throw(f) -> void:
	var tgt = nearest_enemy(f.center(), "foe", 1200.0)
	if tgt == null:
		return
	var dx: float = tgt.center().x - f.center().x
	var p := Combat.Proj.new()
	p.main = self
	p.kind = "orb"
	p.team = "foe"
	p.position = f.center() + Vector2(f.face * 20, -20)
	p.vel = Vector2(clampf(dx * 1.1, -650, 650), -620)
	p.grav = 1500.0
	p.dmg = 8.0
	p.col = Color("aa3ce6")
	add_child(p)

func fire_pillar(x: float) -> void:
	var warn := Fx.Warning.new()
	warn.position = Vector2(x, level.ground_below(x, 300))
	add_child(warn)
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(warn):
		return
	var pl := Combat.Pillar.new()
	pl.col = Color(1, 0.4, 0.15)
	pl.position = warn.position
	pl.on_hit = func():
		for h in heroes():
			if absf(h.position.x - x) < 46:
				hurt_hero(h, 14.0, 1, 3.0, 6.0)
		shake = maxf(shake, 6.0)
	add_child(pl)
	warn.queue_free()

func armor_sparkle(f) -> void:
	Fx.burst(self, f.center() + Vector2(randf_range(-20, 20), randf_range(-40, 30)), Color(1, 0.85, 0.35), 3, 120, 0.06)

func afterimage(f) -> void:
	var g := Fx.Ghost.new()
	g.position = f.position
	g.col = Color(String(f.def.look.shirt))
	g.face = f.face
	add_child(g)

# ---------------- moves ----------------
func on_swing(f, A: Dictionary) -> void:
	var sw := Combat.Swoosh.new()
	sw.position = f.center() + Vector2(f.face * 8, -6)
	sw.scale = Vector2(f.face, 1)
	var hero: bool = f.team == "hero"
	sw.col = Color(1, 0.95, 0.75) if hero else Color(0.75, 0.4, 1)
	match A.get("sw", "jab"):
		"jab":
			sw.radius = 58
			sw.a0 = -0.5
			sw.sweep = 1.0
			sw.width = 14
		"kick":
			sw.radius = 76
			sw.a0 = -1.9
			sw.sweep = 3.2
			sw.width = 24
		"up":
			sw.radius = 76
			sw.a0 = 1.1
			sw.sweep = -2.7
			sw.width = 26
			if hero:
				sw.col = Color(1, 0.85, 0.4)
		"down":
			sw.radius = 76
			sw.a0 = -1.5
			sw.sweep = 3.0
			sw.width = 26
		"big":
			sw.radius = 130 * float(f.def.look.get("scale", 1.0)) / 1.4
			sw.a0 = -2.0
			sw.sweep = 2.8
			sw.width = 36
			sw.col = Color(1, 0.45, 0.35)
	sw.life = 0.22
	add_child(sw)
	Game.sfx("swing", 1.3 if A.get("sw") == "jab" else 0.9)
	if hero and f == player:
		if f.atk == "u4":
			flags.uppercut = true
		if f.atk == "a3":
			flags.slam = true

func on_slam(f) -> void:
	var giant: bool = f.kind == "giant"
	var r := Combat.Ring.new()
	r.main = self
	r.team = f.team
	r.position = f.position + Vector2(0, -6)
	r.flat = true
	r.max_r = 260.0 if giant else 170.0
	r.dmg = (14.0 if giant else 12.0) * (f.dmg_mul() if f.team == "hero" else 1.0)
	r.kb = 5.0
	r.up = 5.0
	r.col = Color(1, 0.5, 0.4) if f.team == "foe" else Color(1, 0.9, 0.6)
	add_child(r)
	Fx.dust(self, f.position, 16, 2.2)
	shake = maxf(shake, 14.0 if giant else 9.0)
	zoom_kick = 0.04

func on_block(f) -> void:
	var n := Fx.Number.new()
	n.setup("BLOCK", Color("7fe8ff"), false)
	n.position = f.center() + Vector2(0, -60)
	add_child(n)
	Fx.burst(self, f.center() + Vector2(f.face * 20, 0), Color(0.5, 0.9, 1), 10, 300, 0.07)
	Game.sfx("block")
	if f == player:
		flags.block = true

func on_jump(f) -> void:
	Fx.dust(self, f.position, 5, 0.8)
	if f == player:
		flags.jump = true
		Game.sfx("jump")

func on_double_jump(f) -> void:
	Fx.burst(self, f.position + Vector2(0, -4), Color.WHITE, 10, 220, 0.07)

func on_land(f, v: float) -> void:
	Fx.dust(self, f.position, 10, 1.0 + v / 2000.0)
	if v > 1100.0:
		shake = maxf(shake, 3.0)

func on_step(f) -> void:
	Fx.dust(self, f.position + Vector2(-f.face * 10, 0), 2, 0.5)

func cast_skill(f) -> void:
	if f.mp < SKILL_COST:
		if f == player:
			hud.toast("Not enough energy yet (the blue bar).", 1.2)
		return
	f.mp -= SKILL_COST
	Game.sfx("skill")
	if f == player:
		flags.skill = true
	var k: String = Data.SKILL.get(f.def.id, "praise")
	if f.def.id == "savan":
		k = SAVAN_SKILLS[f.skill_i % SAVAN_SKILLS.size()]
		f.skill_i += 1
	_skill(f, k)

const SAVAN_SKILLS := ["sword", "agentdash", "armor"]
const SKILL_LABEL := {sword="Spirit Blade", agentdash="Agent Dash", armor="Armor of God"}

func next_skill_name(f) -> String:
	if f.def.id != "savan":
		return ""
	return SKILL_LABEL[SAVAN_SKILLS[f.skill_i % SAVAN_SKILLS.size()]]

func _skill(f, k: String) -> void:
	var m: float = f.dmg_mul()
	var c: Vector2 = f.center()
	var fc: int = f.face
	Fx.burst(self, c, Color(1, 0.95, 0.7), 14, 300, 0.08)
	match k:
		"monkey":
			_proj(f, "monkey", c + Vector2(fc * 20, -10), Vector2(fc * 560, -520), 11 * m, {grav=1700.0, bounce=true, pierce=true, life=2.6, r=20.0})
		"swarm":
			for i in 6:
				_proj(f, "butterfly", c + Vector2(randf_range(-20, 20), randf_range(-30, 10)), Vector2(fc * randf_range(150, 350), randf_range(-300, -100)), 7 * m, {homing=true, life=3.2, col=[Color("4fd0ff"), Color("ff8ad8"), Color("ffd25a")][i % 3]})
		"laser":
			for i in 3:
				get_tree().create_timer(i * 0.12).timeout.connect(func():
					if not is_instance_valid(f): return
					var tg = nearest_enemy(f.center(), f.team, 900.0)
					var dir := Vector2(f.face, 0)
					if tg: dir = (tg.center() - f.center()).normalized()
					_proj(f, "laser", f.center() + Vector2(-f.face * 30, -60), dir * 1300.0, 7 * m, {life=1.0, r=10.0}))
		"pound":
			if f.is_on_floor():
				f.velocity.y = -9.0 * U
			f.slam_fall = true
			f.atk = ""
		"band":
			_proj(f, "band", c + Vector2(fc * 30, -8), Vector2(fc * 1300, 0), 16 * m, {pierce=true, life=0.32, r=18.0, owner=f})
		"sprint":
			f.dash_t = 26.0
			f.dash_set = {}
		"praise":
			var r := Combat.Ring.new()
			r.main = self
			r.team = f.team
			r.position = c
			r.max_r = 300.0
			r.dmg = 14 * m
			r.kb = 6.0
			r.up = 5.0
			r.col = Color(1, 0.85, 0.4)
			add_child(r)
			for h in heroes():
				if h.position.distance_to(f.position) < 400:
					h.hp = minf(h.max_hp, h.hp + 12)
		"agentdash":
			f.dash_t = 22.0
			f.dash_set = {}
			_proj(f, "sword", c + Vector2(fc * 40, -8), Vector2(fc * 1400, 0), 10 * m, {pierce=true, life=0.5, r=36.0})
		"armor":
			f.armor_god = 8.0
			hud.toast("The whole armor of God! (Ephesians 6:11)", 1.8)
			var ring := Combat.Ring.new()
			ring.main = self
			ring.team = f.team
			ring.position = c
			ring.max_r = 220.0
			ring.dmg = 8 * m
			ring.col = Color(1, 0.85, 0.35)
			add_child(ring)
		"sword":
			_proj(f, "sword", c + Vector2(fc * 40, -8), Vector2(fc * 1150, 0), 18 * m, {pierce=true, life=0.9, r=40.0})

func _proj(f, kind: String, pos: Vector2, vel: Vector2, dmg: float, o: Dictionary) -> void:
	var p := Combat.Proj.new()
	p.main = self
	p.kind = kind
	p.team = f.team
	p.position = pos
	p.vel = vel
	p.dmg = dmg
	p.grav = o.get("grav", 0.0)
	p.bounce = o.get("bounce", false)
	p.pierce = o.get("pierce", false)
	p.homing = o.get("homing", false)
	p.life = o.get("life", 2.0)
	p.r = o.get("r", 14.0)
	p.col = o.get("col", Color(1, 0.95, 0.7))
	if o.has("owner"):
		p.look = {owner=o.owner}
	add_child(p)

# ---------------- the SUPER ----------------
func try_super(f) -> void:
	if f != player or mode != "play" or f.glory < 100.0:
		if f == player and f.glory < 100.0:
			hud.toast("Keep hitting shadows to fill the gold SUPER meter!", 1.4)
		return
	f.glory = 0.0
	f.inv = 220.0
	f.atk = ""
	f.velocity = Vector2.ZERO
	mode = "super"
	sup = {t=0.0, fired=false}
	flags.super = true
	Game.sfx("super")
	f.rig.pose = "power"
	var gather := CPUParticles2D.new()
	gather.amount = 60
	gather.lifetime = 0.9
	gather.one_shot = true
	gather.explosiveness = 0.2
	gather.texture = preload("res://scripts/part.gd").glow_tex()
	gather.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	gather.emission_sphere_radius = 320
	gather.gravity = Vector2.ZERO
	gather.radial_accel_min = -900
	gather.radial_accel_max = -700
	gather.scale_amount_min = 0.06
	gather.scale_amount_max = 0.14
	gather.color = Color(1, 0.88, 0.45)
	gather.material = Fx.additive()
	gather.position = f.center()
	gather.z_index = 8
	add_child(gather)
	gather.emitting = true
	gather.finished.connect(gather.queue_free)

func _super_step(real: float) -> void:
	sup.t += real
	if sup.t >= 1.0 and not sup.fired:
		sup.fired = true
		flash = 1.0
		shake = 24.0
		var m: float = player.dmg_mul()
		var vw := get_viewport_rect().size.x
		var left := camera.get_screen_center_position().x - vw / 2
		for f in foes.duplicate():
			if not is_instance_valid(f) or f.dead:
				continue
			var fx: float = f.center().x
			if fx < left - 40 or fx > left + vw + 40:
				continue
			var pl := Combat.Pillar.new()
			pl.position = Vector2(fx, level.ground_below(fx, f.center().y))
			var target = f
			pl.on_hit = func():
				if is_instance_valid(target) and not target.dead:
					var dmg := (90.0 if target == boss else 55.0) * m
					if target.take_hit(dmg, 1, 2.0, 9.0):
						_hit_fx(target.center(), dmg, "hero", null)
			add_child(pl)
		for k in 2:
			var r := Combat.Ring.new()
			r.main = self
			r.team = "hero"
			r.position = player.center()
			r.max_r = 700.0 + k * 200
			r.speed = 1500.0 - k * 300
			r.dmg = 0.0
			r.col = Color(1, 0.9, 0.55)
			add_child(r)
		Fx.burst(self, player.center(), Color(1, 0.92, 0.6), 60, 900, 0.14)
	if sup.t >= 1.25:
		mode = "play"
		_slowmo(0.45)
		_skill(player, Data.SKILL.get(player.def.id, "praise"))
		_skill(player, Data.SKILL.get(player.def.id, "praise"))

func _slowmo(dur: float) -> void:
	Engine.time_scale = 0.35
	slowmo = dur

# ---------------- defeat, grace and the end of a land ----------------
func on_defeat(f) -> void:
	if f == player:
		if Game.own("angel") > 0 and not angel_used:
			angel_used = true
			player.hp = player.max_hp
			player.inv = 150.0
			flash = 0.8
			var a := Fx.Angel.new()
			a.position = player.center() + Vector2(0, -60)
			add_child(a)
			hud.toast("Your Guardian Angel lifts you up! (Psalm 91:11)", 2.5)
			return
		player.hp = 0.0
		falls += 1
		combo = 0
		mode = "grace"
		grace_t = 0.0
		return
	if f.team == "hero":
		f.dead = true
		f.rig.modulate.a = 0.5
		get_tree().create_timer(5.0).timeout.connect(func():
			if is_instance_valid(f):
				f.dead = false
				f.hp = f.max_hp * 0.6
				f.rig.modulate.a = 1.0)
		return
	f.dead = true
	freed += 1
	var c: Vector2 = f.center()
	Fx.burst(self, c, Color("c9b6ff"), 26, 520, 0.12)
	var dv := Fx.Dove.new()
	dv.position = c
	dv.z_index = 8
	add_child(dv)
	for i in 2 + mini(5, combo / 5):
		_coin(c, true, Vector2(randf_range(-260, 260), randf_range(-700, -420)))
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.35)
	tw.tween_callback(f.queue_free)
	foes.erase(f)
	if lock and foe_count() == 0:
		_slowmo(0.35)
		zoom_kick = 0.08

func on_boss_down(b) -> void:
	boss = b
	shake = 26.0
	flash = 1.0
	_slowmo(1.2)
	for f in foes.duplicate():
		if is_instance_valid(f) and f != b and not f.dead:
			on_defeat(f)
	foes.erase(b)
	Fx.burst(self, b.center(), Color(1, 0.95, 0.6), 80, 1000, 0.16)
	get_tree().create_timer(2.2).timeout.connect(func():
		if L.boss == "satan":
			_ending()
		else:
			say(L.outro, func(): _finish(false)))

func _ending() -> void:
	var lines := [["boss", "No... NO! The light is too strong!"], ["j", "Resist the devil, and he will flee from you. (James 4:7)"],
		["n", "Satan fled from the hill, and the chains on the church doors broke apart!"],
		["heike", "The doors are open! Come in, everyone. Let's worship together!"],
		["belinda", "Told you these old bones could still fight! Now, who wants cookies?"],
		["marie", "Everybody sing!"], ["francis", "Well done, warriors. Very well done."],
		["j", "If the Son therefore shall make you free, ye shall be free indeed. (John 8:36)"]]
	Game.music("credits")
	for a in allies:
		a.rig.pose = "cheer"
	say(lines, func(): _finish(true))

func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	player.rig.pose = "cheer"
	Fx.burst(self, player.center(), Color("ffe27a"), 60, 700, 0.12)
	var stars := [true, coins_static >= coins_max, falls == 0]
	var n := stars.count(true)
	var bonus := 20 + n * 15 + (150 if won else 0)
	Game.save.coins = int(Game.save.coins) + coins_n + bonus
	Game.set_stars(Game.level_i, n)
	Game.save.unlocked = maxi(int(Game.save.unlocked), mini(Game.level_i + 2, Data.LEVELS.size()))
	Game.save.help_seen = true
	if won:
		Game.save.won = true
	Game.write_save()
	result = {stars=stars, coins=coins_n, freed=freed, combo=best_combo, bonus=bonus, won=won}
	result_t = 0.0
	mode = "results"

func _respawn() -> void:
	player.hp = player.max_hp
	player.mp = 100.0
	player.inv = 120.0
	player.hurt_t = 0.0
	_put_back()
	mode = "play"

func _put_back() -> void:
	player.position = Vector2(lock.l + 160, 200) if lock else respawn
	player.velocity = Vector2.ZERO
	player.inv = maxf(player.inv, 90.0)
	player.slam_fall = false

# ---------------- dialog ----------------
func say(lines: Array, then: Callable = Callable()) -> void:
	if lines.is_empty():
		if then.is_valid():
			then.call()
		return
	dialog = {lines=lines, i=0, ch=0.0, then=then}
	mode = "dialog"
	if touch:
		touch.release_all()

func _dialog_step(real: float) -> void:
	dialog.ch += real * 55.0
	if Input.is_action_just_pressed("ok") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump"):
		on_button("next")
	if Game.demo and dialog.ch > 40:
		on_button("next")

func on_button(id: String) -> void:
	match id:
		"next":
			if get_tree().paused:
				return
			if mode == "dialog":
				var text: String = dialog.lines[dialog.i][1]
				if dialog.ch < text.length():
					dialog.ch = text.length()
				else:
					dialog.i += 1
					dialog.ch = 0.0
					if dialog.i >= dialog.lines.size():
						mode = "play"
						var then: Callable = dialog.then
						if then.is_valid():
							then.call()
		"resume":
			toggle_pause()
		"retry":
			if mode == "grace" and grace_t > 0.5:
				_respawn()
		"credits":
			Game.set_meta("credits", true)
			Engine.time_scale = 1.0
			get_tree().change_scene_to_file("res://menu.tscn")
		"map":
			get_tree().paused = false
			Game.set_meta("from_land", true)
			Engine.time_scale = 1.0
			Game.write_save()
			get_tree().change_scene_to_file("res://menu.tscn")
		"nextland":
			Engine.time_scale = 1.0
			Game.level_i = mini(Game.level_i + 1, Data.LEVELS.size() - 1)
			get_tree().reload_current_scene()

func toggle_pause() -> void:
	if mode == "results":
		return
	get_tree().paused = not get_tree().paused
	if touch:
		touch.release_all()

# ---------------- tutorial (first land) ----------------
func _setup_tutorial() -> void:
	tut = [
		{key="move", touch="Hold the left pad to run. Slide your thumb to turn around.", keys="Run with A / D or the arrow keys."},
		{key="jump", touch="Tap JUMP to leap over gaps and onto blocks.", keys="Jump with SPACE (or W / Up)."},
		{key="uppercut", touch="Tap ATTACK 4 times: jab, cross, kick, UPPERCUT!", keys="Press J 4 times: jab, cross, kick, UPPERCUT!"},
		{key="slam", touch="In the air, tap ATTACK 3 times to juggle and SLAM down!", keys="In the air, press J 3 times to juggle and SLAM!"},
		{key="block", touch="Hold BLOCK when a shadow swings at you.", keys="Hold S (or Down) to BLOCK a shadow's punch."},
		{key="skill", touch="Tap SKILL for your hero's special power. It uses blue energy.", keys="Press K for your hero's special SKILL (blue energy)."},
		{key="super", touch="The gold meter is full! Tap SUPER for your ultimate!", keys="The gold meter is full! Press U for your ultimate SUPER!"},
	]
	tut_i = 0
	flags.start_x = respawn.x

func _tutorial_check() -> void:
	if tut_i >= tut.size():
		return
	var k: String = tut[tut_i].key
	var done := false
	match k:
		"move": done = player.position.x > flags.start_x + 260
		"super":
			if player.glory < 100.0 and not flags.has("super"):
				player.glory = 100.0
			done = flags.has("super")
		_: done = flags.has(k)
	if done:
		tut_i += 1
		Game.sfx("star")
		Fx.burst(self, player.center() + Vector2(0, -80), Color("7fe08a"), 16, 300, 0.08)
		if tut_i >= tut.size():
			hud.toast("You're ready! Reach the glowing cross at the end of the land.", 3.0)
