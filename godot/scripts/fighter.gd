extends CharacterBody2D
## A hero, a helper friend, or a shadow: movement, the combo chain, blocking,
## skills, juggling and the AI brains. Numbers are tuned in "web units" (per-frame)
## and converted to pixels per second with U.

const Rig := preload("res://scripts/rig.gd")
const U := 180.0
const GRAV := 4860.0

## Ground chain: jab, cross, spin kick, uppercut (launches). Air chain: punch, kick, slam.
const ATK := {
	p1={dur=11, act=[2, 6], dmg=6.0, kb=0.8, up=0.0, pose="punch1", next="p2", sw="jab"},
	p2={dur=12, act=[2, 6], dmg=7.0, kb=0.9, up=0.0, pose="punch2", next="k3", sw="jab"},
	k3={dur=17, act=[4, 9], dmg=9.0, kb=1.8, up=1.0, pose="spin", next="u4", sw="kick", lunge=1.2},
	u4={dur=24, act=[5, 11], dmg=12.0, kb=0.8, up=8.8, pose="uppercut", wind="block", sw="up", hop=5.5},
	a1={dur=12, act=[2, 7], dmg=6.0, kb=0.6, up=2.6, pose="air1", next="a2", sw="jab", air=true},
	a2={dur=14, act=[3, 8], dmg=7.0, kb=1.0, up=2.8, pose="airkick", next="a3", sw="kick", air=true},
	a3={dur=30, act=[4, 30], dmg=14.0, kb=2.5, up=-6.0, pose="slam", sw="down", air=true, slam=true},
	mp={dur=34, act=[18, 22], dmg=8.0, kb=3.0, up=2.0, pose="punch1", wind="wind", sw="jab"},
	smash={dur=46, act=[30, 36], dmg=16.0, kb=6.0, up=5.0, pose="punch1", wind="raise", sw="big", big=true},
	throw={dur=34, act=[99, 99], pose="cast", wind="raise"},
}

var main
var def: Dictionary
var ai := false
var team := "hero"
var kind := "hero"          # hero, ally, m (shadow), t (thrower), b (brute)
var rig
var hp := 100.0
var max_hp := 100.0
var mp := 100.0
var glory := 0.0
var face := 1
var atk := ""
var atk_t := 0.0
var queued := false
var hitset := {}
var hurt_t := 0.0
var inv := 0.0
var coyote := 0.0
var jbuf := 0.0
var air_jumps := 0
var cool := 60.0
var dead := false
var was_floor := true
var step_t := 0.0
var blocking := false
var dash_t := 0.0
var dash_set := {}
var slam_fall := false
var armor := 0.0            # brutes shrug off small hits
var juggle := false
var ai_t := 0.0
var input := {dir=0, jump_p=false, jump_h=false, atk_p=false, skill_p=false, super_p=false, block=false}

func setup(m, d: Dictionary, is_ai: bool, tm: String, k := "hero", extra_look := {}) -> void:
	main = m
	def = d
	ai = is_ai
	team = tm
	kind = k
	hp = float(d.get("hp", 100))
	if kind == "hero":
		hp += Game.own("heart") * 20.0
	max_hp = hp
	if kind == "b":
		armor = 9.0
	if kind == "giant":
		armor = 13.0
	var sc: float = float(d.look.get("scale", 1.0))
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28 * maxf(1.0, sc * 0.8), 74 * sc)
	sh.shape = r
	sh.position = Vector2(0, -r.size.y / 2)
	add_child(sh)
	collision_layer = 2 if team == "hero" else 4
	collision_mask = 1
	floor_snap_length = 10.0
	var lk: Dictionary = d.look.duplicate()
	lk.merge(extra_look, true)
	rig = Rig.new()
	rig.setup(lk)
	add_child(rig)

func box() -> Rect2:
	var sc := float(def.look.get("scale", 1.0))
	return Rect2(position + Vector2(-16 * sc, -80 * sc), Vector2(32 * sc, 80 * sc))

func center() -> Vector2:
	return box().get_center()

func dmg_mul() -> float:
	var m := float(def.get("dmg", 1.0))
	if kind == "hero":
		m *= 1.0 + Game.own("glove") * 0.12
	if kind == "ally":
		m *= 0.45
	return m

func max_air_jumps() -> int:
	var n := 1 if def.get("dbl", false) else 0
	if kind == "hero" and Game.own("wings") > 0:
		n += 1
	return n

func _physics_process(delta: float) -> void:
	if dead or main.frozen(self):
		return
	var f := delta * 60.0
	if ai:
		_think(f)
	var spd := float(def.get("spd", 2.5)) * U
	if kind == "hero":
		spd *= 1.0 + Game.own("sandal") * 0.08
	if hurt_t > 0.0:
		hurt_t -= f
	var busy := hurt_t > 6.0
	if inv > 0.0:
		inv -= f
	var on_floor := is_on_floor()
	if on_floor and juggle and hurt_t <= 0.0:
		juggle = false
	var dir: int = input.dir
	blocking = input.block and on_floor and not busy and atk == "" and dash_t <= 0.0
	if dir != 0 and not busy and atk == "" and not blocking and dash_t <= 0.0:
		face = dir
	# energy
	var regen: float = 9.6 * (1.0 + (Game.own("oil") * 0.25 if kind == "hero" else 0.0))
	mp = minf(100.0, mp + regen * delta)
	# dash (Steven's sprint and some skills)
	if dash_t > 0.0:
		dash_t -= f
		velocity.x = face * 7.5 * U
		velocity.y = 0.0
		main.strike(self, Rect2(box().position - Vector2(10, 0), box().size + Vector2(20, 0)), 14.0 * dmg_mul(), 5.0, 3.0, dash_set)
		if int(dash_t) % 3 == 0:
			main.afterimage(self)
	elif not busy and not blocking:
		var target := dir * spd
		if atk != "" and on_floor:
			target = 0.0
		var acc := 0.3 if on_floor else 0.15
		velocity.x = lerpf(velocity.x, target, 1.0 - pow(1.0 - acc, f))
	else:
		velocity.x *= pow(0.88 if blocking else 0.92, f)
	# jumping
	if input.jump_p:
		jbuf = 7.0
	elif jbuf > 0.0:
		jbuf -= f
	if on_floor:
		coyote = 6.0
		air_jumps = 0
	elif coyote > 0.0:
		coyote -= f
	var jpow := float(def.jmp) * (1.08 if kind == "hero" and Game.own("wings") > 0 else 1.0)
	if jbuf > 0.0 and not busy and dash_t <= 0.0 and not slam_fall:
		if coyote > 0.0:
			velocity.y = -jpow * U
			coyote = 0.0
			jbuf = 0.0
			atk = ""
			rig.kick(0.22)
			main.on_jump(self)
		elif air_jumps < max_air_jumps():
			velocity.y = -jpow * U * 0.92
			air_jumps += 1
			jbuf = 0.0
			atk = ""
			rig.kick(0.16)
			main.on_double_jump(self)
	if not input.jump_h and velocity.y < -3.0 * U and not juggle and atk != "u4":
		velocity.y += 0.5 * U * 60.0 * delta
	# skills and super
	if input.skill_p and not busy and dash_t <= 0.0:
		main.cast_skill(self)
	if input.super_p and not busy:
		main.try_super(self)
	# attacks: tap again during a move to chain into the next one
	if input.atk_p and not busy and not blocking and dash_t <= 0.0 and kind in ["hero", "ally"]:
		if atk == "":
			_start("p1" if on_floor else "a1")
		else:
			queued = true
	var hang := false
	if atk != "":
		var A: Dictionary = ATK[atk]
		atk_t += f
		hang = A.get("air", false) and not A.get("slam", false)
		if A.has("hop") and atk_t <= 2.0 and atk_t + f > 2.0:
			velocity.y = -float(A.hop) * U
		if A.get("slam", false):
			velocity.y = 9.0 * U
			velocity.x = face * 1.2 * U
			slam_fall = true
		if atk_t >= A.act[0] and atk_t <= A.act[1] and A.has("dmg"):
			main.strike(self, _atk_box(A), A.dmg * dmg_mul(), A.kb, A.up, hitset)
		if atk == "throw" and atk_t >= 16.0 and atk_t - f < 16.0:
			main.foe_throw(self)
		var chain_ok: bool = queued and A.has("next") and (on_floor or A.get("air", false))
		if A.get("air", false) and on_floor and not A.get("slam", false):
			atk = ""
		elif atk_t >= A.dur or (chain_ok and atk_t >= A.act[1] + 1):
			if chain_ok:
				_start(A.next)
			else:
				atk = ""
	# gravity
	var g := GRAV
	if hang:
		g *= 0.25
		velocity.y = minf(velocity.y, 1.2 * U)
	if juggle:
		g *= 0.78
	velocity.y += g * delta
	if def.get("float", false) and input.jump_h and velocity.y > U:
		velocity.y = U
	velocity.y = minf(velocity.y, 9.5 * U)
	var fall_v := velocity.y
	move_and_slide()
	on_floor = is_on_floor()
	if on_floor:
		if slam_fall:
			slam_fall = false
			atk = ""
			main.on_slam(self)
		if not was_floor and fall_v > 3.5 * U:
			rig.kick(-0.26 * clampf(fall_v / (8.0 * U), 0.45, 1.0))
			main.on_land(self, fall_v)
		if absf(velocity.x) > 300.0:
			step_t += f
			if step_t > 9.0:
				step_t = 0.0
				main.on_step(self)
	was_floor = on_floor
	rig.face = face
	rig.vel = velocity
	rig.pose = _pose()
	if kind == "hero":
		rig.visible = not (inv > 0.0 and inv < 90.0 and int(inv / 4.0) % 2 == 1)

func _start(n: String) -> void:
	atk = n
	atk_t = 0.0
	queued = false
	hitset = {}
	var A: Dictionary = ATK[n]
	if A.has("lunge"):
		velocity.x = face * float(A.lunge) * U
	if A.get("air", false):
		velocity.y = minf(velocity.y, -0.5 * U)
	main.on_swing(self, A)

func _atk_box(A: Dictionary) -> Rect2:
	var b := box()
	var sc := float(def.look.get("scale", 1.0))
	if A.get("big", false):
		return Rect2(b.position.x + (b.size.x - 10 if face > 0 else -110 * sc / 1.4), b.position.y, 120 * sc / 1.4, b.size.y)
	if A.get("slam", false):
		return Rect2(b.position.x - 20, b.position.y + 30, b.size.x + 40, b.size.y)
	if atk == "u4":
		return Rect2(b.position.x + (14 if face > 0 else -50), b.position.y - 30, 68, b.size.y + 10)
	var x := b.position.x + b.size.x - 6 if face > 0 else b.position.x - 52
	var y := b.position.y + (30.0 if atk == "a2" else 10.0)
	return Rect2(x, y, 58, 46)

func _pose() -> String:
	if hurt_t > 0.0:
		return "launch" if juggle and not is_on_floor() else "hurt"
	if main.power_pose(self):
		return "power"
	if dash_t > 0.0:
		return "dash"
	if blocking:
		return "block"
	if atk != "":
		var A: Dictionary = ATK[atk]
		if atk_t < A.act[0] and A.has("wind"):
			return A.wind
		return A.pose
	if not is_on_floor():
		return "jump" if velocity.y < 0 else "fall"
	if absf(velocity.x) > 60.0:
		return "run"
	return "idle"

## Returns true if the hit landed.
func take_hit(dmg: float, dir: int, kb: float, up: float) -> bool:
	if dead:
		return false
	if team == "hero" and (inv > 0.0 or dash_t > 0.0):
		return false
	if blocking and dir == -face:
		var keep := 0.05 if (kind == "hero" and Game.own("shield") > 0) else 0.25
		hp -= dmg * keep
		velocity.x = dir * kb * 0.5 * U
		main.on_block(self)
		return false
	if kind == "hero":
		dmg *= 1.0 - Game.own("helmet") * 0.12
	hp -= dmg
	rig.flash = 1.0
	var heavy := dmg >= armor
	if heavy:
		hurt_t = 18.0
		atk = ""
		slam_fall = false
		velocity = Vector2(dir * kb * U, -up * U)
		if up > 4.0 or (not is_on_floor() and up > 0.0):
			juggle = true
		if up < 0.0:
			velocity.y = -up * U
	if team == "hero" and not ai:
		inv = 60.0
	if hp <= 0.0:
		hp = 0.0
		main.on_defeat(self)
	return true

# ---------------- brains ----------------
func _think(f: float) -> void:
	for k in ["jump_p", "atk_p", "skill_p", "super_p"]:
		input[k] = false
	input.dir = 0
	input.block = false
	input.jump_h = velocity.y < 0
	if cool > 0.0:
		cool -= f
	ai_t += f
	if hurt_t > 0.0 or atk != "":
		return
	var tgt = main.nearest_enemy(center(), team, 900.0)
	if tgt == null:
		if kind == "ally" and main.player:
			var dxp: float = main.player.position.x - position.x
			if absf(dxp) > 120:
				input.dir = 1 if dxp > 0 else -1
		return
	var dx: float = tgt.center().x - center().x
	var dy: float = tgt.center().y - center().y
	var adx := absf(dx)
	var near := adx < 700.0 and absf(dy) < 260.0
	if kind == "ally":
		face = 1 if dx > 0 else -1
		if adx > 60.0:
			input.dir = face
		if is_on_floor() and (is_on_wall() or (dy < -110 and randf() < 0.05)):
			input.jump_p = true
		if adx < 90.0 and absf(dy) < 100.0 and cool <= 0.0:
			input.atk_p = true
			cool = 6.0 + randf() * 6.0
		if mp >= 60.0 and adx < 400.0 and randf() < 0.01:
			input.skill_p = true
		return
	if not near:
		return
	face = 1 if dx > 0 else -1
	match kind:
		"t":
			if adx < 260.0:
				input.dir = -face
			elif adx > 520.0:
				input.dir = face
			if cool <= 0.0:
				_start("throw")
				cool = 120.0
		"giant":
			if adx > 130.0:
				input.dir = face
			if cool <= 0.0 and adx < 170.0:
				_start("smash")
				cool = 70.0 if hp > max_hp * 0.5 else 45.0
			elif cool <= 0.0 and is_on_floor() and ai_t > 200.0:
				ai_t = 0.0
				velocity = Vector2(clampf(dx * 2.2, -700, 700), -8.5 * U)
				slam_fall = true
				cool = 60.0
			return
		"b":
			if adx > 90.0:
				input.dir = face
			elif cool <= 0.0:
				_start("smash")
				cool = 100.0
		_:
			if adx > 48.0:
				input.dir = face
			if cool <= 0.0 and adx < 86.0 and absf(dy) < 80.0:
				_start("mp")
				cool = 70.0 + randf() * 30.0
	# don't walk off ledges
	if input.dir != 0 and is_on_floor():
		var ahead := position + Vector2(input.dir * 26.0, 8.0)
		if not main.level.solid(int(ahead.x / 48.0), int(ahead.y / 48.0)):
			input.dir = 0
