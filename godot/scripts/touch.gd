extends Control
## On-screen controls for phones: a move pad you can slide across, plus ATTACK, JUMP,
## SKILL, SUPER, BLOCK and pause. Each finger is tracked on its own, and the controls
## press the same input actions as the keyboard.

const Part := preload("res://scripts/part.gd")
const UI := preload("res://scripts/ui.gd")

var main
var touches := {}        # finger index -> {pos, owner}
var held := {}           # action -> true

const BUTTONS := ["attack", "jump", "skill", "super", "block", "pause"]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func _safe() -> Rect2:
	var vs := get_viewport_rect().size
	var r := Rect2(Vector2.ZERO, vs)
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x > 0 and safe.size.x > 0 and safe.size.x < win.x:
		var k := vs.x / float(win.x)
		r.position.x = safe.position.x * k
		r.size.x = safe.size.x * k
	return r

func _pad_rect() -> Rect2:
	var s := _safe()
	return Rect2(s.position.x + 28, s.end.y - 28 - 132, 280, 132)

func _btn(name: String) -> Dictionary:
	var s := _safe()
	var e := s.end
	match name:
		"attack": return {c=e - Vector2(116, 112), r=78.0, col=Color("ff7a5a"), label="ATTACK"}
		"jump": return {c=e - Vector2(282, 80), r=60.0, col=Color("64beff"), label="JUMP"}
		"skill": return {c=e - Vector2(250, 222), r=50.0, col=Color("b07aff"), label="SKILL"}
		"block": return {c=e - Vector2(98, 270), r=48.0, col=Color("5ad0c0"), label="BLOCK"}
		"super": return {c=e - Vector2(414, 96), r=54.0, col=Color("ffc93a"), label="SUPER"}
		"pause": return {c=Vector2(e.x - 52, s.position.y + 112), r=32.0, col=Color("9a8acc"), label=""}
	return {}

func _which(p: Vector2) -> String:
	if _pad_rect().grow(40).has_point(p):
		return "pad"
	var best := ""
	var bd := 1e9
	for n in BUTTONS:
		var b := _btn(n)
		var d := p.distance_to(b.c)
		if d < b.r + 22.0 and d < bd:
			best = n
			bd = d
	return best

func _input(event: InputEvent) -> void:
	if main == null or main.mode in ["results", "dialog"]:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var who := _which(event.position)
			if who == "":
				return
			if get_tree().paused and who != "pause":
				return
			touches[event.index] = {pos=event.position, owner=who}
			if who == "pause":
				main.toggle_pause()
		else:
			if not touches.has(event.index):
				return
			touches.erase(event.index)
		_refresh()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and touches.has(event.index):
		var t: Dictionary = touches[event.index]
		t.pos = event.position
		if t.owner in ["pad", "jump", "attack"]:
			var w := _which(event.position)
			if w in ["pad", "jump", "attack"]:
				t.owner = w
		_refresh()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	var want := {}
	var pr := _pad_rect()
	for t in touches.values():
		match t.owner:
			"pad": want["left" if t.pos.x < pr.get_center().x else "right"] = true
			"jump", "attack", "skill", "super", "block": want[t.owner] = true
	for a in ["left", "right", "jump", "attack", "skill", "super", "block"]:
		var on: bool = want.has(a) and not get_tree().paused
		if on and not held.has(a):
			Input.action_press(a)
			held[a] = true
		elif not on and held.has(a):
			Input.action_release(a)
			held.erase(a)

func release_all() -> void:
	touches.clear()
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()

func _process(_d: float) -> void:
	queue_redraw()

func _glass(c: Vector2, r: float, tint: Color, down: bool, alpha := 1.0) -> void:
	r *= 0.92 if down else 1.0
	draw_circle(c, r, Color(1, 1, 1, 0.3 * alpha) if down else Color(0.02, 0.02, 0.06, 0.32 * alpha), true, -1, true)
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.75 * alpha), 3.0, true)
	draw_arc(c, r - 6, 0, TAU, 48, Color(tint, 0.55 * alpha), 2.0, true)

func _draw() -> void:
	if main == null or main.mode in ["results", "dialog"]:
		return
	if get_tree().paused:
		var pb := _btn("pause")
		_glass(pb.c, pb.r, pb.col, false)
		draw_rect(Rect2(pb.c + Vector2(-10, -12), Vector2(7, 24)), Color.WHITE)
		draw_rect(Rect2(pb.c + Vector2(3, -12), Vector2(7, 24)), Color.WHITE)
		return
	var dim := 0.45 if main.mode in ["dialog", "super"] else 1.0
	# move pad
	var pr := _pad_rect()
	var r := pr.size.y / 2
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12 * dim)
	sb.border_color = Color(1, 1, 1, 0.4 * dim)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	draw_style_box(sb, pr)
	var mid := pr.get_center()
	for side in [-1, 1]:
		var on: bool = held.has("left" if side < 0 else "right")
		var c := mid + Vector2(side * pr.size.x * 0.25, 0)
		if on:
			var hl := StyleBoxFlat.new()
			hl.bg_color = Color(1, 0.88, 0.47, 0.45)
			hl.set_corner_radius_all(int(r))
			hl.anti_aliasing = true
			draw_style_box(hl, Rect2(pr.position + Vector2(0 if side < 0 else pr.size.x / 2, 0), Vector2(pr.size.x / 2, pr.size.y)).grow(-6))
		var s := 26.0 * (0.9 if on else 1.0)
		var chev := PackedVector2Array([c + Vector2(side * -s * 0.4, -s), c + Vector2(side * s * 0.6, 0), c + Vector2(side * -s * 0.4, s)])
		draw_polyline(chev, Color(0, 0, 0, 0.3 * dim), 12, true)
		draw_polyline(chev, Color(1, 1, 1, dim), 8, true)
	var p = main.player
	for n in BUTTONS:
		var b := _btn(n)
		var down: bool = held.has(n)
		var ready := true
		var fill := 1.0
		if n == "skill" and p:
			fill = clampf(p.mp / main.SKILL_COST, 0, 1)
			ready = fill >= 1.0
		if n == "super" and p:
			fill = clampf(p.glory / 100.0, 0, 1)
			ready = fill >= 1.0
		var a := dim * (1.0 if ready else 0.6)
		if n == "super" and ready:
			draw_texture_rect(Part.glow_tex(), Rect2(b.c - Vector2(b.r, b.r) * 1.9, Vector2(b.r, b.r) * 3.8), false, Color(1, 0.8, 0.3, 0.5 + 0.3 * sin(Time.get_ticks_msec() / 120.0)))
		_glass(b.c, b.r, b.col, down, a)
		if n in ["skill", "super"]:
			draw_arc(b.c, b.r + 6, -PI / 2, -PI / 2 + TAU * fill, 40, Color(1, 0.9, 0.5, 0.95 * dim) if n == "super" else Color(0.7, 0.85, 1, 0.95 * dim), 5, true)
		var ic: Vector2 = b.c + Vector2(0, -10 if b.label != "" else 0)
		match n:
			"attack":
				var star := PackedVector2Array()
				for i in 16:
					star.append(ic + Vector2.from_angle(-PI / 2 + i * TAU / 16) * (30.0 if i % 2 == 0 else 14.0))
				draw_colored_polygon(star, Color(1, 1, 1, a))
			"jump":
				draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -24), ic + Vector2(22, 0), ic + Vector2(8, 0), ic + Vector2(8, 18), ic + Vector2(-8, 18), ic + Vector2(-8, 0), ic + Vector2(-22, 0)]), Color(1, 1, 1, a))
			"skill":
				var sp := PackedVector2Array()
				for i in 8:
					sp.append(ic + Vector2.from_angle(-PI / 2 + i * TAU / 8) * (20.0 if i % 2 == 0 else 7.0))
				draw_colored_polygon(sp, Color(1, 1, 1, a))
			"super":
				draw_circle(ic, 10, Color(1, 1, 1, a))
				for i in 8:
					var dv := Vector2.from_angle(i * TAU / 8)
					draw_line(ic + dv * 14, ic + dv * 22, Color(1, 1, 1, a), 4)
			"block":
				draw_colored_polygon(PackedVector2Array([ic + Vector2(-16, -16), ic + Vector2(16, -16), ic + Vector2(14, 4), ic + Vector2(0, 18), ic + Vector2(-14, 4)]), Color(1, 1, 1, a))
			"pause":
				draw_rect(Rect2(b.c + Vector2(-10, -12), Vector2(7, 24)), Color.WHITE)
				draw_rect(Rect2(b.c + Vector2(3, -12), Vector2(7, 24)), Color.WHITE)
		if b.label != "":
			UI.text_c(self, b.label, b.c + Vector2(0, b.r * 0.55), 14 if b.r < 60 else 16, Color(1, 1, 1, a), 5)
