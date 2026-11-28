extends Node2D
## A cartoon character built from jointed parts and animated by blending poses.
## Origin is at the feet. Set `pose` every frame; the rig eases toward it.

const Part := preload("res://scripts/part.gd")
const K := 3.0

var look: Dictionary
var pose := "idle"
var face := 1
var t := 0.0                 # animation clock in 60fps frames (matches the web game)
var blink := 1.0
var look_dx := 0.0
var brow := 0.0
var mouth_open := false
var vel := Vector2.ZERO      # owner's velocity, for hair and lean
var flash := 0.0

var body: Node2D
var hip: Node2D
var torso
var head_pivot: Node2D
var head
var backhair
var parts := {}
var cur := {}
var squash := 0.0
var squash_v := 0.0
var _blink_t := 2.0
var _mono := false

func setup(lk: Dictionary) -> void:
	look = lk
	var sc: float = lk.get("scale", 1.0)
	body = Node2D.new()
	body.scale = Vector2(sc, sc)
	add_child(body)
	if lk.get("shadow", false):
		_add("aura", body, Vector2(0, -16 * K), -6)
	elif Part.STICK:
		_add("backglow", body, Vector2(0, -17 * K), -6)
	hip = Node2D.new()
	hip.position = Vector2(0, -11.2 * K)
	body.add_child(hip)
	var pants := Color(String(lk.pants))
	var top := Color("f4f6fa") if lk.get("coat", false) else Color(String(lk.shirt))
	var mus: bool = lk.get("muscle", false)
	var aw := 4.4 if mus else 3.4
	var covered: bool = lk.get("coat", false) or lk.get("suit", false) or lk.get("shadow", false)
	var fore := top if covered else Color(String(lk.skin))
	# back leg (in shade)
	_leg("B", Vector2(-1.6 * K, 0), Part.shade(pants, -0.14), -3)
	# torso and everything above it
	torso = _add("torso", hip, Vector2.ZERO, 0)
	if lk.has("pack"):
		_add("pack", torso, Vector2.ZERO, -1)
	if lk.get("monkey", false):
		# Mango rides on Alisa's backpack and peeks over her shoulder
		var mk = _add("monkey", torso, Vector2(-9.6 * K, -8.8 * K), -1)
		mk.scale = Vector2(1.5, 1.5)
	if lk.get("cape", false):
		_add("cape", torso, Vector2.ZERO, -3)
	head_pivot = Node2D.new()
	head_pivot.position = Vector2(0, -9.6 * K)
	torso.add_child(head_pivot)
	_add("neck", head_pivot, Vector2.ZERO, -1)
	head = _add("head", head_pivot, Vector2(0, -7.3 * K), 2)
	if Part.STICK and not lk.get("shadow", false) and not lk.has("robe"):
		_add("scarf", head_pivot, Vector2(0, -2.0 * K), 1)
	backhair = _add("backhair", head, Vector2.ZERO, -5)
	if lk.get("halo", false):
		var h = _add("halo", head, Vector2(0, -10.5 * K * 1.16), 4)
		h.use_parent_material = false
	_arm("B", Vector2(-1.4 * K, -7.9 * K), Part.shade(top, -0.14), Part.shade(fore, -0.14), aw, covered, -4)
	_arm("F", Vector2(1.2 * K, -7.9 * K), top, fore, aw, covered, 3)
	_leg("F", Vector2(1.6 * K, 0), pants, 1)
	if lk.has("robe"):
		_add("robe", hip, Vector2.ZERO, 2)
	if lk.has("butterfly"):
		_add("butterfly", self, Vector2(-10 * K, -40 * K), 5)
	cur = _pose_target("idle")
	# one shader on the whole body lets hits flash it white
	var mat := ShaderMaterial.new()
	mat.shader = _flash_shader()
	material = mat
	_share_material(self)

static var _fs: Shader
static func _flash_shader() -> Shader:
	if _fs == null:
		_fs = Shader.new()
		_fs.code = "shader_type canvas_item;\nuniform float flash = 0.0;\nvoid fragment(){ COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash); }"
	return _fs

func _share_material(n: Node) -> void:
	for c in n.get_children():
		if c is CanvasItem:
			c.use_parent_material = true
		_share_material(c)

func _add(kind: String, parent: Node, pos: Vector2, z: int):
	var p := Part.new()
	p.kind = kind
	p.look = look
	p.rig = self
	p.position = pos
	p.z_index = z
	parent.add_child(p)
	parts[kind] = p
	return p

func _limb(parent: Node, pos: Vector2, seg: float, wid: float, c: Color, z: int):
	var p := Part.new()
	p.kind = "limb"
	p.look = look
	p.rig = self
	p.seg = seg
	p.wid = wid
	p.col = c
	p.position = pos
	p.z_index = z
	parent.add_child(p)
	return p

func _leg(side: String, pos: Vector2, c: Color, z: int) -> void:
	var up = _limb(hip, pos, 5.6, 4.4, c, z)
	var lo = _limb(up, Vector2(0, 5.6 * K), 5.6, 3.9, c, -1)
	var shoe := Part.new()
	shoe.kind = "shoe"
	shoe.look = look
	shoe.rig = self
	shoe.position = Vector2(0, 5.6 * K)
	shoe.z_index = 1
	lo.add_child(shoe)
	parts["leg" + side] = [up, lo, shoe]

func _arm(side: String, pos: Vector2, sleeve: Color, fore: Color, aw: float, covered: bool, z: int) -> void:
	var up = _limb(torso, pos, 4.7, aw, sleeve, z)
	var lo = _limb(up, Vector2(0, 4.7 * K), 4.6, aw - (0.2 if covered else 0.5), fore, -1)
	var hand := Part.new()
	hand.kind = "hand"
	hand.look = look if side == "F" else _without_item(look)
	hand.rig = self
	hand.position = Vector2(0, 4.6 * K)
	hand.z_index = 1
	lo.add_child(hand)
	parts["arm" + side] = [up, lo, hand]

func _without_item(lk: Dictionary) -> Dictionary:
	var d := lk.duplicate()
	d.erase("item")
	return d

# ---------- poses (angles from the web game; 0 = limb hanging straight down) ----------
func _pose_target(n: String) -> Dictionary:
	match n:
		"run":
			var a := sin(t * 0.32) * 0.95
			var b := -a
			return {lean=0.2, bob=-absf(a) * 1.2, lF=[a, a - maxf(0, -a) * 1.3 - 0.1], lB=[b, b - maxf(0, -b) * 1.3 - 0.1], aF=[-a * 0.8 + 0.1, -a * 0.8 + 1.1], aB=[a * 0.8 + 0.1, a * 0.8 + 1.1], tilt=0.05}
		"jump": return {lean=0.05, bob=0.0, lF=[1.0, 0.2], lB=[0.2, -0.5], aF=[2.5, 2.8], aB=[-2.0, -1.6], tilt=-0.1}
		"fall": return {lean=0.0, bob=0.0, lF=[0.35, 0.15], lB=[-0.35, -0.1], aF=[1.9, 2.4], aB=[-1.9, -2.4], tilt=0.08}
		"punch1": return {lean=0.22, bob=0.0, lF=[0.45, 0.0], lB=[-0.45, 0.0], aF=[1.57, 1.57], aB=[-0.5, 0.7], tilt=0.05}
		"punch2": return {lean=0.28, bob=0.0, lF=[0.45, 0.0], lB=[-0.45, 0.0], aF=[0.2, 1.3], aB=[1.45, 1.57], tilt=0.08}
		"wind": return {lean=-0.15, bob=0.0, lF=[0.45, 0.0], lB=[-0.45, 0.0], aF=[-0.9, -0.2], aB=[-0.4, 0.4], tilt=-0.05}
		"kick": return {lean=-0.35, bob=0.0, lF=[1.62, 1.62], lB=[-0.12, 0.0], aF=[-0.7, 0.2], aB=[0.9, 1.7], tilt=0.15}
		"airkick": return {lean=-0.25, bob=0.0, lF=[1.25, 1.5], lB=[0.5, -0.5], aF=[2.3, 2.5], aB=[-0.9, -0.4], tilt=0.1}
		"hurt": return {lean=-0.45, bob=0.0, lF=[0.35, 0.2], lB=[-0.25, -0.1], aF=[2.6, 2.9], aB=[-2.4, -2.8], tilt=-0.3}
		"cast": return {lean=0.1, bob=0.0, lF=[0.35, 0.0], lB=[-0.35, 0.0], aF=[2.0, 1.7], aB=[1.8, 1.6], tilt=0.0}
		"raise": return {lean=-0.1, bob=0.0, lF=[0.3, 0.0], lB=[-0.3, 0.0], aF=[3.0, 3.1], aB=[2.8, 3.0], tilt=-0.15}
		"uppercut": return {lean=-0.25, bob=-1.0, lF=[0.7, 0.3], lB=[-0.5, 0.0], aF=[2.75, 3.05], aB=[-0.6, 0.4], tilt=-0.25}
		"slam": return {lean=0.4, bob=0.0, lF=[1.2, 0.6], lB=[0.4, -0.6], aF=[0.6, 0.2], aB=[0.4, 0.1], tilt=0.25}
		"block": return {lean=-0.05, bob=0.8, lF=[0.5, 0.1], lB=[-0.5, 0.0], aF=[1.25, 2.95], aB=[1.0, 2.75], tilt=0.12}
		"dash": return {lean=0.6, bob=0.0, lF=[1.25, 0.4], lB=[-0.9, -1.5], aF=[1.57, 1.57], aB=[-1.2, -0.6], tilt=0.1}
		"air1": return {lean=0.15, bob=0.0, lF=[0.8, 0.2], lB=[0.2, -0.4], aF=[1.6, 1.6], aB=[-0.6, 0.4], tilt=0.05}
		"spin": return {lean=-0.35, bob=0.0, lF=[1.62, 1.62], lB=[-0.12, 0.0], aF=[-0.9, -0.2], aB=[1.2, 1.9], tilt=0.2}
		"launch": return {lean=-0.8, bob=0.0, lF=[0.9, 0.4], lB=[0.3, -0.3], aF=[2.8, 3.0], aB=[-2.5, -2.9], tilt=-0.4}
		"power":
			var q := sin(t * 0.5) * 0.08
			return {lean=-0.12, bob=-1.0, lF=[0.45, 0.1], lB=[-0.45, 0.0], aF=[2.4 + q, 2.9], aB=[-2.4 - q, -2.9], tilt=-0.2}
		"cheer":
			var k := absf(sin(t * 0.2))
			return {lean=0.0, bob=-k * 3, lF=[0.2, 0.0], lB=[-0.2, 0.0], aF=[2.6 + k * 0.3, 2.9], aB=[-2.6 - k * 0.3, -2.9], tilt=-0.1}
		_:
			var b2 := sin(t * 0.07) * 0.4
			return {lean=0.03, bob=b2, lF=[0.14, 0.0], lB=[-0.14, 0.0], aF=[0.25, 0.55], aB=[-0.2, 0.25], tilt=sin(t * 0.03) * 0.04}

func kick(amount: float) -> void:
	## Squash (negative) or stretch (positive) the body, e.g. on landing or jumping.
	squash_v += amount * 10.0

func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)   # a slow first frame must not blow up the springs
	t += delta * 60.0
	var tgt := _pose_target(pose)
	var fast := pose in ["punch1", "punch2", "kick", "airkick", "hurt", "wind", "run", "uppercut", "slam", "dash", "air1", "spin", "launch", "block"]
	var k := 1.0 - exp(-delta * (30.0 if fast else 14.0))
	for key in tgt:
		var v = tgt[key]
		if v is Array:
			var c: Array = cur.get(key, v)
			cur[key] = [lerpf(c[0], v[0], k), lerpf(c[1], v[1], k)]
		else:
			cur[key] = lerpf(cur.get(key, v), v, k)
	# squash & stretch spring
	squash_v += (-squash * 320.0 - squash_v * 16.0) * delta
	squash = clampf(squash + squash_v * delta, -0.35, 0.35)
	squash_v = clampf(squash_v, -12.0, 12.0)
	var sc: float = look.get("scale", 1.0)
	var breathe := sin(t * 0.07) * 0.012 if pose == "idle" else 0.0
	body.scale = Vector2(sc * (1.0 - squash * 0.5), sc * (1.0 + squash + breathe))
	scale.x = face
	_apply()
	# blinking and expressions
	_blink_t -= delta
	var nb := 1.0
	if _blink_t < 0.0:
		nb = 0.15
		if _blink_t < -0.11:
			_blink_t = randf_range(2.0, 4.5)
	if nb != blink:
		blink = nb
		head.queue_redraw()
	var want_mouth := pose in ["punch1", "punch2", "kick", "airkick", "hurt", "cheer", "jump", "uppercut", "slam", "spin", "launch", "power"]
	if want_mouth != mouth_open:
		mouth_open = want_mouth
		head.queue_redraw()
	# animated bits redraw every frame
	if look.get("style") in ["dreads", "ponytail"]:
		backhair.queue_redraw()
	if parts.has("monkey"):
		parts.monkey.queue_redraw()
	if parts.has("cape"):
		parts.cape.queue_redraw()
	if parts.has("scarf"):
		parts.scarf.queue_redraw()
	if parts.has("robe"):
		parts.robe.queue_redraw()
	if parts.has("halo"):
		parts.halo.position.y = -10.5 * K * 1.16 + sin(t * 0.08) * 3.0
	if parts.has("butterfly"):
		var bf = parts.butterfly
		bf.position = Vector2(-10 * K + sin(t * 0.05) * 9, -40 * K * sc + sin(t * 0.13) * 6)
		bf.queue_redraw()
	(material as ShaderMaterial).set_shader_parameter("flash", clampf(flash, 0.0, 0.85))
	flash = maxf(0.0, flash - delta * 7.0)

func _apply() -> void:
	var lean: float = cur.lean
	hip.position.y = (-11.2 + cur.bob * 1.1) * K
	torso.rotation = lean
	head_pivot.rotation = -lean * 0.45 + cur.get("tilt", 0.0) + clampf(-vel.y / 4000.0, -0.12, 0.12)
	for side in ["F", "B"]:
		var lg: Array = parts["leg" + side]
		var a: Array = cur["l" + side]
		lg[0].rotation = -a[0]
		lg[1].rotation = a[0] - a[1]
		lg[2].rotation = a[1]
		var ar: Array = parts["arm" + side]
		var b: Array = cur["a" + side]
		ar[0].rotation = -b[0] - lean
		ar[1].rotation = b[0] - b[1]
		ar[2].rotation = b[1]
