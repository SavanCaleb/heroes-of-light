extends CharacterBody2D
## A hero or shadow minion: movement, jumping, the punch-punch-kick combo, and getting hit.
## Numbers come from the web game (per-frame units) and are converted to pixels per second.

const Rig := preload("res://scripts/rig.gd")
const U := 180.0            # web px/frame -> Godot px/s
const GRAV := 4860.0

const ATK := {
	p1={dur=13, act=[3, 7], dmg=7.0, kb=1.2, up=0.0, pose="punch1", next="p2"},
	p2={dur=13, act=[3, 7], dmg=7.0, kb=1.2, up=0.0, pose="punch2", next="k3"},
	k3={dur=22, act=[5, 11], dmg=13.0, kb=4.5, up=3.0, pose="kick", wind="punch2"},
	air={dur=22, act=[2, 18], dmg=10.0, kb=3.0, up=2.0, pose="airkick", low=true},
	mp={dur=34, act=[18, 22], dmg=8.0, kb=3.0, up=2.0, pose="punch1", wind="wind"},
}

var main
var def: Dictionary
var ai := false
var team := "hero"
var rig
var hp := 100.0
var max_hp := 100.0
var mp := 100.0
var face := 1
var atk := ""
var atk_t := 0.0
var queued := false
var hitset := {}
var hurt_t := 0.0
var inv := 0.0
var coyote := 0.0
var jbuf := 0.0
var dbl := false
var cool := 60.0
var dead := false
var was_floor := true
var step_t := 0.0
var input := {dir=0, jump_p=false, jump_h=false, atk_p=false}

func setup(m, d: Dictionary, is_ai: bool, tm: String) -> void:
	main = m
	def = d
	ai = is_ai
	team = tm
	hp = float(d.get("hp", 100))
	max_hp = hp
	var sh := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 74)
	sh.shape = r
	sh.position = Vector2(0, -37)
	add_child(sh)
	collision_layer = 2 if team == "hero" else 4
	collision_mask = 1
	floor_snap_length = 10.0
	rig = Rig.new()
	rig.setup(d.look)
	add_child(rig)

func box() -> Rect2:
	return Rect2(position + Vector2(-15, -78), Vector2(30, 78))

func center() -> Vector2:
	return position + Vector2(0, -40)

func dmg_mul() -> float:
	return float(def.get("dmg", 1.0))

func _physics_process(delta: float) -> void:
	if dead:
		return
	if main.hitstop > 0.0:
		return
	var f := delta * 60.0
	if team == "foe":
		_think(f)
	var spd := float(def.get("spd", 2.5)) * U
	if hurt_t > 0.0:
		hurt_t -= f
	var busy := hurt_t > 8.0
	if inv > 0.0:
		inv -= f
	var dir: int = input.dir
	var on_floor := is_on_floor()
	if dir != 0 and not busy and (atk == "" or not on_floor):
		face = dir
	if not busy:
		var target := dir * spd
		if atk != "" and on_floor:
			target = 0.0
		var acc := 0.3 if on_floor else 0.15
		velocity.x = lerpf(velocity.x, target, 1.0 - pow(1.0 - acc, f))
	else:
		velocity.x *= pow(0.9, f)
	# jumping: buffered presses, a little grace after leaving a ledge, double jump for some heroes
	if input.jump_p:
		jbuf = 7.0
	elif jbuf > 0.0:
		jbuf -= f
	if on_floor:
		coyote = 6.0
	elif coyote > 0.0:
		coyote -= f
	if jbuf > 0.0 and not busy:
		if coyote > 0.0:
			velocity.y = -float(def.jmp) * U
			coyote = 0.0
			jbuf = 0.0
			rig.kick(0.22)
			main.on_jump(self)
		elif def.get("dbl", false) and not dbl:
			velocity.y = -float(def.jmp) * U * 0.92
			dbl = true
			jbuf = 0.0
			rig.kick(0.16)
			main.on_double_jump(self)
	if not input.jump_h and velocity.y < -3.0 * U:
		velocity.y += 0.5 * U * 60.0 * delta
	# attacks
	if input.atk_p and not busy and team == "hero":
		if atk == "":
			_start("p1" if on_floor else "air")
		else:
			queued = true
	if atk != "":
		var A: Dictionary = ATK[atk]
		atk_t += f
		if atk_t >= A.act[0] and atk_t <= A.act[1]:
			main.strike(self, _atk_box(A), A.dmg * dmg_mul(), A.kb, A.up)
		if atk == "air" and on_floor:
			atk = ""
		elif atk_t >= A.dur:
			if queued and A.has("next") and on_floor:
				_start(A.next)
				if atk == "k3":
					velocity.x = face * 1.5 * U
			else:
				atk = ""
	# gravity (Sarah floats while holding jump)
	velocity.y += GRAV * delta
	if def.get("float", false) and input.jump_h and velocity.y > U:
		velocity.y = U
	velocity.y = minf(velocity.y, 8.0 * U)
	var fall_v := velocity.y
	move_and_slide()
	on_floor = is_on_floor()
	if on_floor:
		dbl = false
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
	if not ai:
		rig.visible = not (inv > 0.0 and int(inv / 4.0) % 2 == 1)

func _start(n: String) -> void:
	atk = n
	atk_t = 0.0
	queued = false
	hitset = {}
	main.on_swing(self)

func _atk_box(A: Dictionary) -> Rect2:
	var b := box()
	var x := b.position.x + 24.0 if face > 0 else b.position.x - 48.0
	var y := b.position.y + (36.0 if A.get("low", false) else 12.0)
	return Rect2(x, y, 54, 42)

func _pose() -> String:
	if hurt_t > 0.0:
		return "hurt"
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

func take_hit(dmg: float, dir: int, kb: float, up: float) -> bool:
	if dead:
		return false
	if team == "hero" and inv > 0.0:
		return false
	hp -= dmg
	rig.flash = 1.0
	hurt_t = 16.0
	atk = ""
	velocity = Vector2(dir * kb * U, -up * U)
	if team == "hero":
		inv = 55.0
	if hp <= 0.0:
		hp = 0.0
		dead = true
		main.on_defeat(self)
	return true

# ---------- shadow minion brain ----------
func _think(f: float) -> void:
	input.dir = 0
	if cool > 0.0:
		cool -= f
	var p = main.player
	if atk != "" or hurt_t > 0.0 or p == null:
		return
	var dx: float = p.position.x - position.x
	var dy: float = p.position.y - position.y
	var near := absf(dx) < 690.0 and absf(dy) < 210.0
	if near:
		face = 1 if dx > 0 else -1
		if absf(dx) > 46.0:
			input.dir = face
		if cool <= 0.0 and absf(dx) < 80.0 and absf(dy) < 70.0:
			atk = "mp"
			atk_t = 0.0
			hitset = {}
			cool = 70.0
			return
	# don't walk off ledges
	if input.dir != 0 and is_on_floor():
		var ahead := position + Vector2(input.dir * 24.0, 8.0)
		if not main.level.solid(int(ahead.x / 48.0), int(ahead.y / 48.0)):
			input.dir = 0
