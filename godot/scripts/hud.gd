extends Control
## Everything drawn on top of the game: bars, coins, progress, combo, banners, tutorial,
## dialog, the SUPER cinematic, results and the pause menu.

const UI := preload("res://scripts/ui.gd")
const Data := preload("res://scripts/data.gd")
const Part := preload("res://scripts/part.gd")

var main
var banner_text := ""
var banner_sub := ""
var banner_t := 9.0
var toast_text := ""
var toast_t := 0.0
var hits: Array = []        # tappable rects drawn this frame: [Rect2, id]
var t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

func banner(s: String, sub := "") -> void:
	banner_text = s
	banner_sub = sub
	banner_t = 0.0

func toast(s: String, dur := 2.5) -> void:
	toast_text = s
	toast_t = dur

func _process(d: float) -> void:
	t += d
	banner_t += d
	toast_t -= d
	queue_redraw()

func tap(p: Vector2) -> String:
	for h in hits:
		if (h[0] as Rect2).has_point(p):
			return h[1]
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var id := tap(event.position)
		if id != "":
			main.on_button(id)
			get_viewport().set_input_as_handled()
		elif main.mode in ["dialog"]:
			main.on_button("next")
			get_viewport().set_input_as_handled()

func _bar(r: Rect2, v: float, c1: Color, c2: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	sb.set_corner_radius_all(int(r.size.y / 2))
	draw_style_box(sb, r)
	if v > 0.0:
		var w := maxf(r.size.y, r.size.x * clampf(v, 0, 1))
		var fill := StyleBoxFlat.new()
		fill.bg_color = c2
		fill.set_corner_radius_all(int(r.size.y / 2))
		draw_style_box(fill, Rect2(r.position, Vector2(w, r.size.y)))
		var hi := StyleBoxFlat.new()
		hi.bg_color = c1
		hi.set_corner_radius_all(int(r.size.y / 2))
		draw_style_box(hi, Rect2(r.position, Vector2(w, r.size.y * 0.55)))

## A slanted bar like in fighting games.
func _slant(p: Vector2, w: float, h: float, v: float, c1: Color, c2: Color) -> void:
	var sk := h * 0.6
	draw_colored_polygon(PackedVector2Array([p + Vector2(sk, -2), p + Vector2(w + sk + 3, -2), p + Vector2(w + 2, h + 2), p + Vector2(-3, h + 2)]), Color(0, 0, 0, 0.55))
	if v > 0.0:
		var fw := w * clampf(v, 0, 1)
		draw_polygon(PackedVector2Array([p + Vector2(sk, 0), p + Vector2(fw + sk, 0), p + Vector2(fw, h), p + Vector2(0, h)]), PackedColorArray([c1, c1, c2, c2]))
		draw_line(p + Vector2(sk + 1, 1.5), p + Vector2(fw + sk - 1, 1.5), Color(1, 1, 1, 0.45), 2)

func _draw() -> void:
	hits.clear()
	var p = main.player
	if p == null:
		return
	var vs := get_viewport_rect().size
	var vw := vs.x
	var right_pad := 90.0 if Game.touch else 0.0
	# --- hero panel ---
	# fighting-game style slanted bars, no box
	var acc := Color(String(p.def.look.get("accent", p.def.look.shirt)))
	draw_circle(Vector2(44, 52), 26, Color(0, 0, 0, 0.45), true, -1, true)
	draw_circle(Vector2(44, 52), 22, acc, true, -1, true)
	draw_circle(Vector2(44, 52), 13, Color("17131f"), true, -1, true)
	draw_circle(Vector2(48, 50), 2.2, Color.WHITE, true, -1, true)
	draw_circle(Vector2(54, 50), 2.0, Color.WHITE, true, -1, true)
	UI.text(self, p.def.name.to_upper(), Vector2(80, 38), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	_slant(Vector2(78, 46), 330, 18, p.hp / p.max_hp, Color("ff5a6a"), Color("c01c34"))
	UI.text(self, str(int(ceil(p.hp))), Vector2(78, 62), 14, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 322, 4)
	_slant(Vector2(74, 68), 280, 8, p.mp / 100.0, Color("8ad8ff"), Color("2a78d8"))
	var full: bool = p.glory >= 100.0
	for i in 4:
		var seg := clampf(p.glory / 25.0 - i, 0, 1)
		_slant(Vector2(70 + i * 62, 82), 56, 10, seg, Color("fff3a0") if full else Color("ffd25a"), Color("ff9a20"))
	if full:
		draw_texture_rect(Part.glow_tex(), Rect2(40, 50, 320, 70), false, Color(1, 0.85, 0.4, 0.25 + 0.2 * sin(t * 8.0)))
		UI.text(self, "SUPER READY!", Vector2(320, 94), 15, Color("fff6c0") if int(t * 4) % 2 == 0 else Color("ffb020"), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
	var ns: String = main.next_skill_name(p)
	if ns != "":
		UI.text(self, "Next skill: " + ns, Vector2(72, 116), 14, Color("c8b8ff"), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
	# --- coins ---
	UI.coin_badge(self, Vector2(vw - 190 - right_pad, 14), Game.save.coins + main.coins_n)
	UI.text(self, "freed " + str(main.freed), Vector2(vw - 186 - right_pad, 86), 17, Color("e8e0ff"))
	# --- land progress ---
	var lw: float = main.level.width_px
	var prog := clampf(p.position.x / maxf(1.0, lw - 60.0), 0, 1)
	var bw := 380.0
	var bx := vw * 0.5 - bw / 2
	UI.text(self, "Story %d: %s" % [Game.level_i + 1, main.L.name], Vector2(bx, 34), 20, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, bw, 5)
	_bar(Rect2(bx, 44, bw, 12), prog, Color("fff0a0"), Color("ffb020"))
	for z in main.zones:
		var zx: float = bx + bw * clampf((z.x + 640.0) / lw, 0, 1)
		draw_set_transform(Vector2(zx, 50), PI / 4)
		draw_rect(Rect2(-6, -6, 12, 12), Color("7fe08a") if z.done else Color("ff5a6a"))
		draw_set_transform(Vector2.ZERO)
	if main.arena:
		var ax: float = bx + bw * clampf((main.arena.x + 640.0) / lw, 0, 1)
		draw_circle(Vector2(ax, 50), 11, UI.INK)
		draw_circle(Vector2(ax, 50), 8, Color("ff4b5c"))
	draw_circle(Vector2(bx + bw * prog, 50), 13, UI.INK)
	draw_circle(Vector2(bx + bw * prog, 50), 10, Color(String(p.def.look.shirt)))
	draw_circle(Vector2(bx + bw * prog, 50), 5, Color(String(p.def.look.skin)))
	# --- combo ---
	if main.combo >= 2:
		var k := 1.0 + clampf(main.combo_t - 2.2, 0, 0.2) * 2.0
		var cx := vw - 150 - right_pad
		draw_set_transform(Vector2(cx, 190), -0.08, Vector2(k, k))
		UI.text_c(self, str(main.combo), Vector2(0, 0), 68, Color("ffe27a") if main.combo < 15 else Color("ff8a5a"), 9)
		UI.text_c(self, "HITS", Vector2(0, 44), 22, Color.WHITE, 6)
		var rt := _rating(main.combo)
		if rt != "":
			UI.text_c(self, rt, Vector2(0, 74), 26, Color("9ff0b0") if main.combo < 25 else Color("ff8ad8"), 7)
		draw_set_transform(Vector2.ZERO)
	# --- boss bar ---
	if main.boss and is_instance_valid(main.boss) and not main.boss.dead:
		var b = main.boss
		var name: String = b.name_text if "name_text" in b else "GIANT OF FEAR"
		UI.text_c(self, name, Vector2(vw / 2, vs.y - 64), 24, Color("ffb0b8"), 7)
		_bar(Rect2(vw / 2 - 300, vs.y - 48, 600, 20), b.hp / b.max_hp, Color("ff8080"), Color("a01030"))
	# --- wave label ---
	if main.lock and main.wave_label != "":
		UI.text_c(self, main.wave_label, Vector2(vw / 2, 92), 22, Color("ffb0b8"), 6)
	# --- tutorial ---
	if main.tut_i < main.tut.size():
		var step: Dictionary = main.tut[main.tut_i]
		var w := 760.0
		var lines := UI.wrap(step.touch if Game.touch else step.keys, w - 150, 21)
		var r := Rect2(vw / 2 - w / 2, 112, w, 30 + lines.size() * 28)
		UI.panel(self, r, true, 0.85)
		UI.text_c(self, "TIP %d/%d" % [main.tut_i + 1, main.tut.size()], r.position + Vector2(58, r.size.y / 2), 16, UI.GOLD, 4)
		for i in lines.size():
			UI.text(self, lines[i], r.position + Vector2(112, 38 + i * 28), 21, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	# --- toast ---
	if toast_t > 0.0:
		var a := clampf(toast_t * 3.0, 0, 1)
		var lines := UI.wrap(toast_text, 620, 22)
		var r2 := Rect2(vw / 2 - 340, 190, 680, 24 + lines.size() * 30)
		UI.panel(self, r2, false, 0.8 * a)
		for i in lines.size():
			UI.text_c(self, lines[i], Vector2(vw / 2, r2.position.y + 26 + i * 30), 22, Color(1, 0.92, 0.66, a), 5)
	# --- banner ---
	if banner_t < 2.4:
		var a2 := clampf(minf(banner_t * 4.0, (2.4 - banner_t) * 3.0), 0, 1)
		var slide := (1.0 - minf(1.0, banner_t * 5.0)) * 300.0
		draw_rect(Rect2(0, vs.y * 0.34, vw, 130), Color(0.05, 0.03, 0.12, 0.6 * a2))
		draw_rect(Rect2(0, vs.y * 0.34, vw, 4), Color(UI.GOLD, a2))
		draw_rect(Rect2(0, vs.y * 0.34 + 126, vw, 4), Color(UI.GOLD, a2))
		UI.text_c(self, banner_text, Vector2(vw / 2 + slide, vs.y * 0.34 + 54), 64, Color(1, 0.82, 0.35, a2), 10)
		if banner_sub != "":
			UI.text_c(self, banner_sub, Vector2(vw / 2 - slide, vs.y * 0.34 + 104), 22, Color(1, 1, 1, a2), 5)
	# --- the SUPER cinematic ---
	if main.mode == "super":
		_super_overlay(vs)
	if main.flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.98, 0.9, main.flash))
	# --- dialog ---
	if main.mode == "dialog":
		_dialog(vs)
	if main.mode == "grace":
		_try_again(vs)
	if main.mode == "results":
		_results(vs)
	if get_tree().paused:
		_pause(vs)

func _try_again(vs: Vector2) -> void:
	## A gentle note when you fall: no game over, just get back up.
	var a := clampf(main.grace_t * 3.0, 0, 1)
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.03, 0.12, 0.55 * a))
	var r := Rect2(vs.x / 2 - 300, vs.y / 2 - 170 + (1.0 - a) * 40, 600, 330)
	UI.panel(self, r, true, 0.95 * a)
	draw_texture_rect(Part.glow_tex(), Rect2(r.get_center() - Vector2(120, 210), Vector2(240, 200)), false, Color(1, 0.85, 0.45, 0.5 * a))
	UI.star(self, r.position + Vector2(r.size.x / 2, 62), 30, true)
	UI.text_c(self, "Don't give up!", r.position + Vector2(r.size.x / 2, 126), 40, Color(1, 0.82, 0.35, a), 8)
	UI.text_c(self, "Every hero falls sometimes. Let's try again!", r.position + Vector2(r.size.x / 2, 172), 21, Color(1, 0.97, 0.85, a), 5)
	UI.text_c(self, "\"A just man falleth seven times, and riseth up again.\"", r.position + Vector2(r.size.x / 2, 210), 17, Color(1, 0.91, 0.66, a), 4)
	UI.text_c(self, "Proverbs 24:16", r.position + Vector2(r.size.x / 2, 234), 15, Color(0.85, 0.78, 1, a), 4)
	var b := Rect2(r.position.x + r.size.x / 2 - 140, r.end.y - 76, 280, 58)
	UI.button(self, b, "TRY AGAIN", true, 26)
	hits.append([b, "retry"])

func _rating(n: int) -> String:
	if n >= 40: return "HALLELUJAH!"
	if n >= 25: return "UNSTOPPABLE!"
	if n >= 15: return "AWESOME!"
	if n >= 8: return "GREAT!"
	if n >= 4: return "NICE!"
	return ""

func _super_overlay(vs: Vector2) -> void:
	var st: float = main.sup.t
	var a := clampf(st * 3.0, 0, 1) * (1.0 - clampf((st - 1.0) * 6.0, 0, 1))
	# darken the edges and stream golden light toward the hero
	draw_texture_rect(Part.glow_tex(), Rect2(Vector2(-vs.x * 0.5, -vs.y * 0.5), vs * 2), false, Color(0, 0, 0, 0))
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.04, 0.02, 0.1, 0.55 * a))
	var c: Vector2 = main.hero_screen_pos()
	for i in 14:
		var ang := i * TAU / 14 + st * 2.0
		var r0 := 900.0 * (1.0 - fposmod(st * 1.4 + i * 0.07, 1.0))
		draw_line(c + Vector2.from_angle(ang) * r0, c + Vector2.from_angle(ang) * (r0 + 120), Color(1, 0.9, 0.5, 0.7 * a), 5)
	draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(220, 260), Vector2(440, 440)), false, Color(1, 0.88, 0.45, 0.7 * a))
	# name banner sweeps in on a slanted gold band
	var k := clampf(st * 4.0, 0, 1)
	var y := vs.y * 0.66
	var band := PackedVector2Array([Vector2(-20, y - 50 + (1 - k) * 80), Vector2(vs.x + 20, y - 80 + (1 - k) * 80), Vector2(vs.x + 20, y + 10 - (1 - k) * 80), Vector2(-20, y + 40 - (1 - k) * 80)])
	draw_colored_polygon(band, Color(1, 0.75, 0.15, 0.92 * a))
	band.append(band[0])
	draw_polyline(band, Color(1, 0.97, 0.8, a), 4)
	var tx := vs.x * 0.5 + (1 - k) * 600
	UI.text_c(self, String(main.player.def.sup).to_upper(), Vector2(tx, y - 22), 54, Color(1, 1, 1, a), 10)
	UI.text_c(self, main.player.def.name + "'s SUPER", Vector2(tx, y + 18), 20, Color(0.25, 0.12, 0, a), 0)

func _dialog(vs: Vector2) -> void:
	var d: Dictionary = main.dialog
	var line: Array = d.lines[d.i]
	var r := Rect2(30, vs.y - 210, vs.x - 60, 180)
	UI.panel(self, r, true, 0.94)
	var who: String = line[0]
	var col := Color("9ff0b0")
	var nm := "Story"
	if who == "hero":
		nm = main.player.def.name
		col = Color("b8d8ff")
	elif who == "boss":
		nm = main.boss_name()
		col = Color("ff9aa8")
	elif Data.NPCS.has(who):
		nm = Data.NPCS[who].name
	elif who == "j":
		nm = "Jesus"
		col = Color("ffe28a")
	UI.text(self, nm, r.position + Vector2(36, 46), 28, col)
	var shown := String(line[1]).substr(0, int(d.ch))
	var lines := UI.wrap(shown, r.size.x - 80, 24)
	for i in lines.size():
		UI.text(self, lines[i], r.position + Vector2(36, 86 + i * 32), 24, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
	if d.ch >= String(line[1]).length() and int(t * 3) % 2 == 0:
		UI.text(self, "tap to continue  >" if Game.touch else "press ENTER  >", r.position + Vector2(r.size.x - 260, r.size.y - 18), 18, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)

func _results(vs: Vector2) -> void:
	var res: Dictionary = main.result
	var rt: float = main.result_t
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.04, 0.02, 0.12, 0.6))
	var r := Rect2(vs.x / 2 - 330, 60, 660, 590)
	UI.panel(self, r, true, 0.95)
	UI.text_c(self, "STORY COMPLETE!" if not res.get("won", false) else "THE CHAINS ARE BROKEN!", Vector2(vs.x / 2, 118), 48, UI.GOLD, 9)
	UI.text_c(self, main.L.name, Vector2(vs.x / 2, 160), 22, Color("e8d8ff"), 5)
	var why := ["Finished the land", "Found every coin", "No falls"]
	for i in 3:
		var at := 0.3 + i * 0.3
		var on: bool = res.stars[i] and rt > at
		var k := clampf((rt - at) * 6.0, 0, 1)
		var sc := 1.0 + (1.0 - k) * 0.8 if on else 1.0
		UI.star(self, Vector2(vs.x / 2 - 140 + i * 140, 230), 36 * sc, on)
		UI.text_c(self, why[i], Vector2(vs.x / 2 - 140 + i * 140, 290), 17, UI.CREAM if res.stars[i] else Color("8a7aaa"), 4)
	var rows := [["Coins found", str(res.coins)], ["Shadows freed", str(res.freed)], ["Best combo", str(res.combo) + " hits"], ["Star bonus", "+" + str(res.bonus) + " coins"]]
	for i in rows.size():
		if rt > 1.2 + i * 0.12:
			UI.text(self, rows[i][0], Vector2(r.position.x + 70, 350 + i * 40), 24, Color("c8b8e8"))
			UI.text(self, rows[i][1], Vector2(r.position.x + 70, 350 + i * 40), 24, UI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 140)
	if rt > 1.8:
		UI.text_c(self, "Lesson: " + main.L.lesson, Vector2(vs.x / 2, 516), 19, Color("9ff0b0"), 4)
		UI.text_c(self, "\"" + main.L.verse + "\"", Vector2(vs.x / 2, 546), 16, Color("ffe9a8"), 4)
		var b1 := Rect2(vs.x / 2 - 260, 574, 240, 60)
		var b2 := Rect2(vs.x / 2 + 20, 574, 240, 60)
		UI.button(self, b1, "MAP & SHOP", false, 26)
		hits.append([b1, "map"])
		if res.get("won", false):
			UI.button(self, b2, "THE CREDITS  >", true, 24)
			hits.append([b2, "credits"])
		elif Game.level_i + 1 < Data.LEVELS.size():
			UI.button(self, b2, "NEXT STORY  >", true, 26)
			hits.append([b2, "nextland"])

func _pause(vs: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.08, 0.7))
	UI.text_c(self, "PAUSED", Vector2(vs.x / 2, vs.y * 0.3), 72, UI.GOLD, 10)
	var b1 := Rect2(vs.x / 2 - 150, vs.y * 0.42, 300, 64)
	var b2 := Rect2(vs.x / 2 - 150, vs.y * 0.42 + 84, 300, 64)
	UI.button(self, b1, "KEEP PLAYING", true, 26)
	UI.button(self, b2, "QUIT TO MAP", false, 26)
	hits.append([b1, "resume"])
	hits.append([b2, "map"])
