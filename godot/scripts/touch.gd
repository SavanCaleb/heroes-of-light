extends Control
## On-screen controls for phones: a move pad you can slide across, JUMP, ATTACK and pause.
## Each finger is tracked on its own, so you can run, jump and punch at the same time.
## The controls press the same input actions as the keyboard.

const OL := Color("1b1430")

var main
var touches := {}        # finger index -> {pos, owner}
var held := {}           # action -> true
var paused := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

# ---------- layout (in viewport pixels, kept clear of the phone's notch) ----------
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
	return Rect2(s.position.x + 28, s.end.y - 28 - 132, 270, 132)

func _btn(name: String) -> Dictionary:
	var s := _safe()
	var e := s.end
	match name:
		"attack": return {c=e - Vector2(110, 110), r=76.0}
		"jump": return {c=e - Vector2(282, 84), r=62.0}
		"pause": return {c=Vector2(e.x - 52, s.position.y + 112), r=30.0}
	return {}

func _which(p: Vector2) -> String:
	if _pad_rect().grow(40).has_point(p):
		return "pad"
	for n in ["pause", "attack", "jump"]:
		var b := _btn(n)
		if p.distance_to(b.c) < b.r + 26.0:
			return n
	if Rect2(16, 16, 360, 92).has_point(p):
		return "hero"
	return ""

# ---------- input ----------
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var who := _which(event.position)
			touches[event.index] = {pos=event.position, owner=who}
			if who == "pause":
				_toggle_pause()
			elif who == "hero" and not paused:
				main.next_hero()
		else:
			touches.erase(event.index)
		_refresh()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if touches.has(event.index):
			var t: Dictionary = touches[event.index]
			t.pos = event.position
			# a thumb sliding off the pad onto a button (or back) switches what it presses
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
			"pad":
				want["left" if t.pos.x < pr.get_center().x else "right"] = true
			"jump":
				want["jump"] = true
			"attack":
				want["attack"] = true
	for a in ["left", "right", "jump", "attack"]:
		var on: bool = want.has(a) and not paused
		if on and not held.has(a):
			Input.action_press(a)
			held[a] = true
		elif not on and held.has(a):
			Input.action_release(a)
			held.erase(a)
	queue_redraw()

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		for a in held.keys():
			Input.action_release(a)
		held.clear()
	queue_redraw()

func _notification(what: int) -> void:
	# let go of everything if the app is switched away mid-press
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		touches.clear()
		_refresh()

# ---------- drawing ----------
func _glass_circle(c: Vector2, r: float, tint: Color, down: bool) -> void:
	r *= 0.92 if down else 1.0
	draw_circle(c + Vector2(0, 5), r, Color(0, 0, 0, 0.25), true, -1, true)
	draw_circle(c, r, Color(tint.darkened(0.2), 0.62 if down else 0.45), true, -1, true)
	var g := preload("res://scripts/part.gd").glow_tex()
	draw_texture_rect(g, Rect2(c + Vector2(-r * 0.8, -r * 0.95), Vector2(r * 1.6, r * 1.3)), false, Color(tint.lightened(0.5), 0.75 if down else 0.5))
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.5), 2.5, true)
	draw_arc(c, r - 6, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, 0.35), 3, true)

func _label(s: String, c: Vector2, size: int) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string_outline(f, c - Vector2(w / 2, -size * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 5, Color(0, 0, 0, 0.5))
	draw_string(f, c - Vector2(w / 2, -size * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var pr := _pad_rect()
	# move pad: one pill, the side under your thumb lights up
	var r := pr.size.y / 2
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.12)
	sb.border_color = Color(1, 1, 1, 0.4)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(r))
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
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
			var half := Rect2(pr.position + Vector2(0 if side < 0 else pr.size.x / 2, 0), Vector2(pr.size.x / 2, pr.size.y))
			draw_style_box(hl, half.grow(-6))
		var s := 26.0 * (0.9 if on else 1.0)
		var chev := PackedVector2Array([c + Vector2(side * -s * 0.4, -s), c + Vector2(side * s * 0.6, 0), c + Vector2(side * -s * 0.4, s)])
		draw_polyline(chev, Color(0, 0, 0, 0.3), 12, true)
		draw_polyline(chev, Color.WHITE, 8, true)
	draw_line(mid + Vector2(0, -r + 18), mid + Vector2(0, r - 18), Color(1, 1, 1, 0.2), 2)
	# jump
	var j := _btn("jump")
	_glass_circle(j.c, j.r, Color("64beff"), held.has("jump"))
	var a: Vector2 = j.c + Vector2(0, -12)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, -24), a + Vector2(24, 2), a + Vector2(9, 2), a + Vector2(9, 22), a + Vector2(-9, 22), a + Vector2(-9, 2), a + Vector2(-24, 2)]), Color.WHITE)
	_label("JUMP", j.c + Vector2(0, 34), 16)
	# attack
	var at := _btn("attack")
	_glass_circle(at.c, at.r, Color("ff7a5a"), held.has("attack"))
	var star := PackedVector2Array()
	var sc: Vector2 = at.c + Vector2(0, -10)
	for i in 16:
		var ang := -PI / 2 + i * TAU / 16
		star.append(sc + Vector2.from_angle(ang) * (32.0 if i % 2 == 0 else 15.0))
	draw_colored_polygon(star, Color.WHITE)
	_label("ATTACK", at.c + Vector2(0, 44), 16)
	if paused:
		var vs := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.08, 0.6))
		_label("PAUSED", vs / 2 + Vector2(0, -20), 64)
		_label("Tap II to keep playing", vs / 2 + Vector2(0, 40), 24)
	# pause button stays on top so it can be tapped again
	var p := _btn("pause")
	_glass_circle(p.c, p.r, Color("9a8acc"), false)
	draw_rect(Rect2(p.c + Vector2(-10, -12), Vector2(7, 24)), Color.WHITE)
	draw_rect(Rect2(p.c + Vector2(3, -12), Vector2(7, 24)), Color.WHITE)
