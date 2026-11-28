extends Control
## Title screen, How to Play, hero select, the land map and the Manna Market shop.

const Data := preload("res://scripts/data.gd")
const Rig := preload("res://scripts/rig.gd")
const UI := preload("res://scripts/ui.gd")
const Part := preload("res://scripts/part.gd")

const DESC := {
	alisa="Loud, funny explorer with a backpack and Mango the monkey. Double jump!",
	sarah="Quiet, sweet and smart. Loves butterflies and drives REALLY fast. Hold JUMP to float.",
	shalom="The tech guy. Laser bot and computer brains.",
	zion="Mariana's husband. Tall, full of energy, the most HP and the hardest hits.",
	mariana="Zion's wife and a physiotherapist. Long-reach band whips.",
	steven="Short, muscular and the fastest runner. Great with kids.",
	edikan="A doctor and the youth leader. Praise that blasts shadows and heals friends.",
	savan="Secret agent of the Kingdom. Sharp suit, black shades, sword waves. Double jump!",
}
const SKILL_NAME := {monkey="Mango Mayhem", swarm="Flutter Storm", laser="Laser Bot 3000", pound="Thunder Stomp", band="Snap-Back Band", sprint="Lightning Lap", praise="Hallelujah Blast", sword="Spirit Blade"}
const LAND_COL := {garden="5cc35a", desert="f2b860", sea="3a7ac8", forest="2f6a5a", city="9b8bd0", snow="dfeaff", mount="c8464a"}

var state := "title"
var t := 0.0
var sel_hero := 0
var sel_land := 0
var shop_i := 0
var msg := ""
var msg_t := 0.0
var help_then := "title"
var hits: Array = []
var stage: Node2D
var big_rig
var map_rig
var logo: Texture2D

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Engine.time_scale = 1.0
	sel_hero = int(Game.save.hero)
	sel_land = clampi(Game.level_i, 0, int(Game.save.unlocked) - 1)
	logo = load("res://icon.png")
	stage = Node2D.new()
	add_child(stage)
	var start := "map" if Game.save.help_seen and Game.has_meta("from_land") else "title"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("screen="):
			start = a.substr(7)
	_go(start)

func _go(s: String) -> void:
	state = s
	for c in stage.get_children():
		c.queue_free()
	big_rig = null
	map_rig = null
	var vs := get_viewport_rect().size
	match s:
		"title":
			var xs := [0.1, 0.17, 0.24, 0.31, 0.69, 0.76, 0.83, 0.9]
			for i in 8:
				var x: float = vs.x * xs[i]
				_rig(Data.HEROES[i].look, Vector2(x, _hill_y(x, vs) + 6), 0.95, "cheer" if i % 3 == 0 else "idle", 1 if x < vs.x / 2 else -1)
			_rig(Data.NPCS.heike.look, Vector2(vs.x * 0.42, _hill_y(vs.x * 0.42, vs) + 4), 0.9, "raise", 1)
		"select":
			for i in 8:
				var r := _card_rect(i, vs)
				_rig(Data.HEROES[i].look, r.position + Vector2(r.size.x / 2, r.size.y - 44), 0.95, "idle", 1)
			big_rig = _rig(Data.HEROES[sel_hero].look, Vector2(vs.x - 120, 470), 2.0, "idle", -1)
		"map":
			map_rig = _rig(Data.HEROES[sel_hero].look, _node_pos(sel_land, vs) + Vector2(0, -34), 0.75, "cheer", 1)
		"shop":
			var lk: Dictionary = Data.HEROES[sel_hero].look.duplicate()
			if Game.own("cape") > 0: lk.cape = true
			if Game.own("halo") > 0: lk.halo = true
			big_rig = _rig(lk, Vector2(maxf(24.0, vs.x * 0.5 - 640 + 24) + 300, vs.y - 18), 1.2, "cheer", 1)

func _rig(lk: Dictionary, pos: Vector2, sc: float, pose: String, face: int):
	var r := Rig.new()
	r.setup(lk)
	r.position = pos
	r.scale = Vector2(sc, sc)
	r.pose = pose
	r.face = face
	r.t = randf() * 100.0
	stage.add_child(r)
	return r

func _process(d: float) -> void:
	t += d
	msg_t -= d
	if big_rig and state == "select":
		var poses := ["idle", "punch1", "punch2", "spin", "uppercut", "jump", "cheer", "idle"]
		big_rig.pose = poses[int(t * 2.2) % poses.size()]
	queue_redraw()
	if Input.is_action_just_pressed("back"):
		_back()
	elif Input.is_action_just_pressed("ok"):
		_confirm()
	elif Input.is_action_just_pressed("right"):
		_move(1)
	elif Input.is_action_just_pressed("left"):
		_move(-1)

func _back() -> void:
	match state:
		"help": _go(help_then)
		"select": _go("title")
		"map": _go("select")
		"shop": _go("map")

func _confirm() -> void:
	match state:
		"title": _act("play")
		"help": _act("gotit")
		"select": _act("choose")
		"map": _act("go")
		"shop": _act("buy")

func _move(d: int) -> void:
	match state:
		"select":
			sel_hero = (sel_hero + d + 8) % 8
			_go("select")
		"map":
			sel_land = clampi(sel_land + d, 0, int(Game.save.unlocked) - 1)
			_go("map")
		"shop":
			shop_i = (shop_i + d + Data.SHOP.size()) % Data.SHOP.size()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		for h in hits:
			if (h[0] as Rect2).has_point(event.position):
				_act(h[1])
				get_viewport().set_input_as_handled()
				return

func _act(id: String) -> void:
	if id.begins_with("hero"):
		sel_hero = int(id.substr(4))
		_go("select")
		return
	if id.begins_with("land"):
		var i := int(id.substr(4))
		if i < int(Game.save.unlocked):
			sel_land = i
			_go("map")
		return
	if id.begins_with("item"):
		shop_i = int(id.substr(4))
		return
	match id:
		"play":
			if not Game.save.help_seen:
				help_then = "select"
				_go("help")
			else:
				_go("select")
		"help":
			help_then = state
			_go("help")
		"gotit":
			Game.save.help_seen = true
			Game.write_save()
			_go(help_then)
		"shop": _go("shop")
		"choose":
			Game.save.hero = sel_hero
			Game.write_save()
			_go("map")
		"go":
			Game.level_i = sel_land
			Game.save.hero = sel_hero
			Game.write_save()
			get_tree().change_scene_to_file("res://main.tscn")
		"back": _back()
		"buy": _buy()

func _buy() -> void:
	var it: Dictionary = Data.SHOP[shop_i]
	var n: int = Game.own(it.id)
	if n >= int(it.max):
		msg = "You already have the most of this!"
	elif int(Game.save.coins) < int(it.price):
		msg = "Not enough coins yet. Free more shadows and grab every coin!"
	else:
		Game.save.coins = int(Game.save.coins) - int(it.price)
		Game.save.own[it.id] = n + 1
		Game.write_save()
		msg = "You got " + it.name + "!"
		if it.id in ["cape", "halo"]:
			_go("shop")
	msg_t = 2.5

# ---------------- layout helpers ----------------
func _hill_y(x: float, vs: Vector2) -> float:
	return vs.y * 0.62 + pow((x - vs.x / 2) / (vs.x / 2), 2) * 90.0

func _card_rect(i: int, vs: Vector2) -> Rect2:
	var col := i % 4
	var row := i / 4
	var w := 150.0
	var h := 230.0
	var x0 := maxf(30.0, vs.x * 0.5 - 640 + 30)
	return Rect2(x0 + col * (w + 14), 100 + row * (h + 14), w, h)

func _node_pos(i: int, vs: Vector2) -> Vector2:
	var n := Data.LEVELS.size()
	var x := lerpf(vs.x * 0.1, vs.x * 0.9, float(i) / (n - 1))
	var y := 300.0 + (90.0 if i % 2 == 0 else -40.0)
	return Vector2(x, y)

func _button(r: Rect2, label: String, id: String, primary := false, size := 28) -> void:
	UI.button(self, r, label, primary, size)
	hits.append([r, id])

# ---------------- drawing ----------------
func _draw() -> void:
	hits.clear()
	var vs := get_viewport_rect().size
	_sky(vs)
	match state:
		"title": _title(vs)
		"help": _help(vs)
		"select": _select(vs)
		"map": _map(vs)
		"shop": _shop(vs)
	if msg_t > 0.0:
		var a := clampf(msg_t * 2.0, 0, 1)
		UI.panel(self, Rect2(vs.x / 2 - 320, vs.y - 96, 640, 60), true, 0.9 * a)
		UI.text_c(self, msg, Vector2(vs.x / 2, vs.y - 66), 22, Color(1, 0.92, 0.66, a), 5)

func _sky(vs: Vector2) -> void:
	var top := Color("120a26")
	var bot := Color("3e2256")
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)]), PackedColorArray([top, top, bot, bot]))
	for i in 80:
		var tw := 0.5 + 0.5 * sin(t * 2.0 + i)
		draw_circle(Vector2(fmod(i * 97.3, vs.x), fmod(i * 41.7, vs.y * 0.7)), 1 + tw, Color(1, 1, 1, 0.3 + 0.5 * tw))
	draw_texture_rect(Part.glow_tex(), Rect2(vs.x * 0.5 - 500, -300, 1000, 700), false, Color(1, 0.8, 0.4, 0.18))

func _title(vs: Vector2) -> void:
	# the hill and the church
	var hill := PackedVector2Array()
	var x := 0.0
	while x <= vs.x + 1:
		hill.append(Vector2(x, _hill_y(x, vs)))
		x += 16.0
	hill.append(vs)
	hill.append(Vector2(0, vs.y))
	var cols := PackedColorArray()
	for p in hill:
		cols.append(Color("2a4434").lerp(Color("14241c"), clampf((p.y - vs.y * 0.6) / (vs.y * 0.4), 0, 1)))
	draw_polygon(hill, cols)
	var c := Vector2(vs.x / 2, _hill_y(vs.x / 2, vs))
	draw_texture_rect(Part.glow_tex(), Rect2(c - Vector2(260, 330), Vector2(520, 420)), false, Color(1, 0.85, 0.5, 0.45 + 0.1 * sin(t * 2.0)))
	draw_rect(Rect2(c + Vector2(-90, -130), Vector2(180, 130)), Color("f6f1e6"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-110, -128), c + Vector2(0, -200), c + Vector2(110, -128)]), Color("c0582c"))
	draw_rect(Rect2(c + Vector2(-24, -260), Vector2(48, 66)), Color("f6f1e6"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-34, -258), c + Vector2(0, -300), c + Vector2(34, -258)]), Color("c0582c"))
	draw_rect(Rect2(c + Vector2(-4, -345), Vector2(8, 46)), UI.GOLD)
	draw_rect(Rect2(c + Vector2(-18, -332), Vector2(36, 8)), UI.GOLD)
	draw_rect(Rect2(c + Vector2(-30, -74), Vector2(60, 74)), Color("fff1b0"))
	for wx in [-70, 46]:
		draw_rect(Rect2(c + Vector2(wx, -110), Vector2(24, 30)), Color("ffe28a"))
	draw_rect(Rect2(c + Vector2(-90, -124), Vector2(180, 26)), Color("d8343a"))
	UI.text_c(self, "FREEDOM", c + Vector2(0, -111), 18, Color.WHITE, 0)
	# logo and title
	draw_texture_rect(Part.glow_tex(), Rect2(vs.x / 2 - 520, -40, 1040, 260), false, Color(1, 0.8, 0.3, 0.25))
	var f := UI.font()
	var title := "HEROES OF LIGHT"
	var sz := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 86)
	var tp := Vector2(vs.x / 2 - sz.x / 2 + 50, 128)
	draw_string_outline(f, tp + Vector2(0, 6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 86, 18, Color(0, 0, 0, 0.4))
	draw_string_outline(f, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 86, 14, UI.INK)
	draw_string(f, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 86, Color("ffd25a"))
	draw_string(f, tp + Vector2(0, -2), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 86, Color(1, 0.97, 0.8, 0.35 + 0.2 * sin(t * 3.0)))
	draw_texture_rect(logo, Rect2(tp.x - 128, 34, 112, 112), false)
	UI.text_c(self, "Break the chains. Bring the songs home.", Vector2(vs.x / 2 + 50, 176), 24, Color("e8d8ff"), 5)
	var bw := 300.0
	_button(Rect2(vs.x / 2 - bw / 2, vs.y * 0.7, bw, 72), "PLAY", "play", true, 36)
	_button(Rect2(vs.x / 2 - bw - 20, vs.y * 0.7 + 90, bw, 58), "HOW TO PLAY", "help", false, 24)
	_button(Rect2(vs.x / 2 + 20, vs.y * 0.7 + 90, bw, 58), "SHOP", "shop", false, 24)
	UI.coin_badge(self, Vector2(vs.x - 200, 24), int(Game.save.coins))
	UI.text_c(self, "a game by Savan", Vector2(vs.x / 2, vs.y - 18), 18, Color("ffe9c8"), 4)

func _help(vs: Vector2) -> void:
	UI.text_c(self, "HOW TO PLAY", Vector2(vs.x / 2, 56), 52, UI.GOLD, 10)
	var cw := minf(400.0, (vs.x - 100) / 3)
	var x0 := vs.x / 2 - cw * 1.5 - 20
	var cols := [
		["CONTROLS", (["Left pad: run (slide to turn)", "JUMP: jump (tap again in the air)", "ATTACK: punch and kick", "BLOCK: hold to defend", "SKILL: your hero's power", "SUPER: your ultimate move", "II: pause"] if Game.touch else ["A / D or arrows: run", "SPACE / W: jump", "J: punch and kick", "S / Down: hold to block", "K: your hero's SKILL", "U or SHIFT: SUPER", "ESC: pause"])],
		["FIGHTING", ["Tap ATTACK 4 times for jab, cross, kick and an UPPERCUT that launches shadows", "Jump after them: punch, kick and SLAM them down", "Hits build a combo and fill the gold SUPER meter", "SKILL uses blue energy, which refills by itself"]],
		["YOUR QUEST", ["Cross 7 lands to free the church on the hill", "BATTLE zones lock the screen until every shadow is freed", "Talk to friends for help and healing", "Grab coins, earn 3 stars per land, and shop in the Manna Market"]],
	]
	for i in 3:
		var r := Rect2(x0 + i * (cw + 20), 100, cw, vs.y - 230)
		UI.panel(self, r)
		UI.text(self, cols[i][0], r.position + Vector2(24, 44), 26, Color("9ff0b0"))
		var y := r.position.y + 84
		for line in cols[i][1]:
			var wl := UI.wrap("- " + line, cw - 48, 19)
			for w in wl:
				UI.text(self, w, Vector2(r.position.x + 24, y), 19, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
				y += 26
			y += 8
	_button(Rect2(vs.x / 2 - 150, vs.y - 104, 300, 70), "GOT IT!", "gotit", true, 32)

func _select(vs: Vector2) -> void:
	UI.text_c(self, "CHOOSE YOUR HERO", Vector2(vs.x * 0.5 - 200, 56), 44, UI.GOLD, 9)
	for i in 8:
		var r := _card_rect(i, vs)
		UI.panel(self, r, i == sel_hero, 0.9)
		UI.text_c(self, Data.HEROES[i].name, r.position + Vector2(r.size.x / 2, r.size.y - 22), 22, UI.GOLD if i == sel_hero else UI.CREAM, 5)
		hits.append([r, "hero" + str(i)])
	var h: Dictionary = Data.HEROES[sel_hero]
	var pr := Rect2(vs.x - 560, 90, 530, vs.y - 120)
	UI.panel(self, pr, false, 0.75)
	UI.text(self, h.name, pr.position + Vector2(30, 56), 46, UI.GOLD)
	UI.text(self, h.title, pr.position + Vector2(30, 92), 24, Color("e8d8ff"))
	var y := pr.position.y + 130
	for l in UI.wrap(DESC[h.id], 260, 19):
		UI.text(self, l, Vector2(pr.position.x + 30, y), 19, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		y += 26
	y += 10
	UI.text(self, "SKILL", Vector2(pr.position.x + 30, y), 17, Color("b8a8ff"))
	UI.text(self, SKILL_NAME[Data.SKILL[h.id]], Vector2(pr.position.x + 30, y + 26), 21, UI.CREAM)
	UI.text(self, "SUPER", Vector2(pr.position.x + 30, y + 60), 17, Color("ffd25a"))
	UI.text(self, h.sup, Vector2(pr.position.x + 30, y + 86), 21, UI.CREAM)
	var stats := [["SPEED", clampi(int(round((h.spd - 1.9) * 4)), 1, 5)], ["JUMP", clampi(int(round((h.jmp - 7.6) * 4.5)), 1, 5)], ["HP", clampi(int(round(h.hp / 26.0)), 1, 5)], ["POWER", clampi(int(round(h.get("dmg", 1.0) * 4)), 1, 5)]]
	for i in stats.size():
		var sy := pr.end.y - 190 + i * 30
		UI.text(self, stats[i][0], Vector2(pr.position.x + 30, sy), 17, Color("c8b8e8"))
		for k in 5:
			var sb := StyleBoxFlat.new()
			sb.bg_color = UI.GOLD if k < stats[i][1] else Color("3a2f5a")
			sb.set_corner_radius_all(5)
			draw_style_box(sb, Rect2(pr.position.x + 120 + k * 34, sy - 14, 28, 12))
	_button(Rect2(pr.position.x + 30, pr.end.y - 66, 260, 54), "CHOOSE  >", "choose", true, 26)

func _map(vs: Vector2) -> void:
	UI.text_c(self, "CHOOSE A LAND", Vector2(vs.x / 2, 56), 44, UI.GOLD, 9)
	UI.coin_badge(self, Vector2(vs.x - 200, 24), int(Game.save.coins))
	var n := Data.LEVELS.size()
	var path := PackedVector2Array()
	for i in n:
		path.append(_node_pos(i, vs))
	for i in n - 1:
		var a := path[i]
		var b := path[i + 1]
		var steps := 12
		for k in steps:
			if k % 2 == 0:
				var unlocked := i + 1 < int(Game.save.unlocked)
				draw_line(a.lerp(b, float(k) / steps), a.lerp(b, float(k + 1) / steps), UI.GOLD if unlocked else Color(1, 1, 1, 0.25), 6)
	for i in n:
		var p := path[i]
		var L: Dictionary = Data.LEVELS[i]
		var open := i < int(Game.save.unlocked)
		var sel := i == sel_land
		if sel:
			draw_texture_rect(Part.glow_tex(), Rect2(p - Vector2(90, 90), Vector2(180, 180)), false, Color(1, 0.85, 0.4, 0.5 + 0.2 * sin(t * 4.0)))
		draw_circle(p, 46, UI.INK, true, -1, true)
		draw_circle(p, 40, Color(LAND_COL[L.theme]) if open else Color("3a2f5a"), true, -1, true)
		draw_circle(p + Vector2(-12, -12), 14, Color(1, 1, 1, 0.25), true, -1, true)
		if open:
			UI.text_c(self, str(i + 1), p + Vector2(0, 2), 34, UI.INK if L.theme in ["snow", "desert", "garden"] else Color.WHITE, 0 if L.theme in ["snow", "desert", "garden"] else 5)
			for k in 3:
				UI.star(self, p + Vector2(-28 + k * 28, 62), 12, k < Game.stars(i))
			if L.has("boss"):
				UI.text_c(self, "BOSS", p + Vector2(0, -60), 16, Color("ff9aa8"), 4)
		else:
			draw_rect(Rect2(p + Vector2(-14, -6), Vector2(28, 22)), Color("8a7aaa"))
			draw_arc(p + Vector2(0, -6), 10, PI, TAU, 12, Color("8a7aaa"), 5)
		hits.append([Rect2(p - Vector2(56, 56), Vector2(112, 112)), "land" + str(i)])
	var L2: Dictionary = Data.LEVELS[sel_land]
	var r := Rect2(vs.x / 2 - 420, vs.y - 230, 840, 200)
	UI.panel(self, r, true, 0.9)
	UI.text(self, "Land %d: %s" % [sel_land + 1, L2.name], r.position + Vector2(30, 52), 34, UI.GOLD)
	var y := r.position.y + 92
	for l in UI.wrap(L2.intro + ("  A boss waits at the end!" if L2.has("boss") else ""), 520, 20):
		UI.text(self, l, Vector2(r.position.x + 30, y), 20, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		y += 28
	_button(Rect2(r.end.x - 270, r.position.y + 40, 240, 70), "PLAY  >", "go", true, 32)
	_button(Rect2(r.end.x - 270, r.position.y + 124, 115, 50), "HEROES", "back", false, 18)
	_button(Rect2(r.end.x - 145, r.position.y + 124, 115, 50), "SHOP", "shop", false, 18)

func _shop(vs: Vector2) -> void:
	UI.text_c(self, "MANNA MARKET", Vector2(vs.x * 0.5 - 150, 56), 44, UI.GOLD, 9)
	UI.coin_badge(self, Vector2(vs.x - 200, 24), int(Game.save.coins))
	var cols := 5
	var w := 150.0
	var h := 150.0
	var x0 := maxf(24.0, vs.x * 0.5 - 640 + 24)
	for i in Data.SHOP.size():
		var it: Dictionary = Data.SHOP[i]
		var r := Rect2(x0 + (i % cols) * (w + 12), 92 + (i / cols) * (h + 12), w, h)
		UI.panel(self, r, i == shop_i, 0.9)
		UI.icon(self, it.id, r.position + Vector2(w / 2, 58 + (sin(t * 4.0) * 3.0 if i == shop_i else 0.0)), 1.0)
		UI.text_c(self, it.name, r.position + Vector2(w / 2, h - 40), 15, UI.CREAM, 4)
		var n: int = Game.own(it.id)
		if n >= int(it.max):
			UI.text_c(self, "OWNED", r.position + Vector2(w / 2, h - 16), 16, Color("9ff0b0"), 4)
		else:
			UI.coin(self, r.position + Vector2(w / 2 - 26, h - 16), 8)
			UI.text(self, str(it.price), r.position + Vector2(w / 2 - 12, h - 9), 18, Color("ffe27a") if int(Game.save.coins) >= int(it.price) else Color("b08a8a"), HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		if int(it.max) > 1:
			for k in int(it.max):
				draw_circle(r.position + Vector2(w - 16 - k * 14, 16), 5, UI.GOLD if k < n else Color("3a2f5a"))
		hits.append([r, "item" + str(i)])
	var it2: Dictionary = Data.SHOP[shop_i]
	var pr := Rect2(x0 + cols * (w + 12) + 10, 92, minf(380.0, vs.x - (x0 + cols * (w + 12) + 30)), 480)
	UI.panel(self, pr, true, 0.92)
	UI.icon(self, it2.id, pr.position + Vector2(pr.size.x / 2, 96), 2.0)
	UI.text_c(self, it2.name, pr.position + Vector2(pr.size.x / 2, 200), 28, UI.GOLD, 6)
	var y := pr.position.y + 244
	for l in UI.wrap(it2.desc, pr.size.x - 50, 20):
		UI.text_c(self, l, Vector2(pr.position.x + pr.size.x / 2, y), 20, UI.CREAM, 4)
		y += 28
	if int(it2.max) > 1:
		UI.text_c(self, "Owned %d / %d" % [Game.own(it2.id), it2.max], Vector2(pr.position.x + pr.size.x / 2, pr.end.y - 120), 18, Color("c8b8e8"), 4)
	var maxed: bool = Game.own(it2.id) >= int(it2.max)
	if maxed:
		UI.text_c(self, "You have it all!", Vector2(pr.position.x + pr.size.x / 2, pr.end.y - 60), 24, Color("9ff0b0"), 5)
	else:
		_button(Rect2(pr.position.x + 30, pr.end.y - 92, pr.size.x - 60, 64), "BUY   " + str(it2.price), "buy", int(Game.save.coins) >= int(it2.price), 28)
	_button(Rect2(x0, vs.y - 86, 200, 58), "<  BACK", "back", false, 24)
