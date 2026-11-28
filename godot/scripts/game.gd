extends Node
## Always-loaded game state (registered as the "Game" autoload): the save file,
## the chosen hero and land, and the bonuses from shop items.

const Data := preload("res://scripts/data.gd")
const SAVE_PATH := "user://heroes_save.json"

var save := {coins=0, own={}, unlocked=1, stars=[], hero=0, help_seen=false, won=false}
var level_i := 0           # land being played
var last_result := {}      # filled when a land ends, shown on the map
var demo := false
var touch := false

func _ready() -> void:
	# Poppins for every piece of text in the game
	ThemeDB.fallback_font = load("res://fonts/Poppins-SemiBold.ttf")
	load_save()
	for a in OS.get_cmdline_user_args():
		if a == "demo":
			demo = true
		elif a == "touch":
			touch = true
		elif a.begins_with("hero="):
			save.hero = clampi(int(a.substr(5)), 0, 7)
		elif a.begins_with("land="):
			level_i = clampi(int(a.substr(5)), 0, Data.LEVELS.size() - 1)
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		touch = true
	_inputs()
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_music.append(p)
	for i in 8:
		var s := AudioStreamPlayer.new()
		s.volume_db = -6.0
		add_child(s)
		_sfx_players.append(s)
	_make_sfx()

# ---------------- music: one track at a time, cross-fading ----------------
var _music: Array = []
var _music_name := ""
var _cur := 0
var muted := false

func music(name: String) -> void:
	if name == _music_name or demo:
		return
	_music_name = name
	var path := "res://music/%s.ogg" % name
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamOggVorbis = load(path)
	stream.loop = true
	var old: AudioStreamPlayer = _music[_cur]
	_cur = 1 - _cur
	var nw: AudioStreamPlayer = _music[_cur]
	nw.stream = stream
	nw.volume_db = -40.0
	nw.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nw, "volume_db", -80.0 if muted else -8.0, 1.2)
	tw.tween_property(old, "volume_db", -80.0, 1.2)
	tw.chain().tween_callback(func(): if old != _music[_cur]: old.stop())

# ---------------- sound effects, made from simple waves at start-up ----------------
var _sfx := {}
var _sfx_players: Array = []
var _sfx_i := 0

func sfx(name: String, pitch := 1.0) -> void:
	if muted or not _sfx.has(name) or demo:
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_players.size()
	p.stream = _sfx[name]
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()

func _make_sfx() -> void:
	_sfx.hit = _wave(0.14, func(t, k): return (sin(TAU * (160.0 - 90.0 * k) * t) * 0.8 + randf_range(-1, 1) * 0.5 * (1.0 - k)) * pow(1.0 - k, 2.0))
	_sfx.big = _wave(0.3, func(t, k): return (sin(TAU * (110.0 - 60.0 * k) * t) + randf_range(-1, 1) * 0.6 * (1.0 - k)) * pow(1.0 - k, 1.6))
	_sfx.swing = _wave(0.12, func(t, k): return randf_range(-1, 1) * sin(PI * k) * 0.35)
	_sfx.jump = _wave(0.16, func(t, k): return sin(TAU * (380.0 + 420.0 * k) * t) * (1.0 - k) * 0.35)
	_sfx.coin = _wave(0.22, func(t, k): return sin(TAU * (988.0 if k < 0.3 else 1319.0) * t) * (1.0 - k) * 0.3)
	_sfx.block = _wave(0.12, func(t, k): return sin(TAU * 900.0 * t) * sin(TAU * 1210.0 * t) * (1.0 - k) * 0.5)
	_sfx.skill = _wave(0.4, func(t, k): return sin(TAU * (520.0 + 700.0 * k) * t) * sin(PI * k) * 0.35)
	_sfx.super = _wave(1.2, func(t, k): return (sin(TAU * 220.0 * t) + sin(TAU * 277.0 * t) + sin(TAU * 330.0 * t) + sin(TAU * 440.0 * t * (1.0 + k))) * 0.12 * sin(PI * k))
	_sfx.star = _wave(0.35, func(t, k): return (sin(TAU * 784.0 * t) + sin(TAU * 1175.0 * t)) * 0.18 * (1.0 - k))

func _wave(dur: float, f: Callable) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var v: float = clampf(f.call(t, float(i) / n), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			save[k] = d[k]
	if not save.own is Dictionary:
		save.own = {}
	if not save.stars is Array:
		save.stars = []

func write_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))

func own(id: String) -> int:
	return int(save.own.get(id, 0))

func hero_def() -> Dictionary:
	return Data.HEROES[int(save.hero)]

func stars(i: int) -> int:
	return int(save.stars[i]) if i < save.stars.size() else 0

func set_stars(i: int, n: int) -> void:
	while save.stars.size() <= i:
		save.stars.append(0)
	save.stars[i] = maxi(int(save.stars[i]), n)

## The four actions every control scheme presses.
func _inputs() -> void:
	var map := {
		"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D], "jump": [KEY_SPACE, KEY_UP, KEY_W],
		"attack": [KEY_J, KEY_X, KEY_F], "skill": [KEY_K, KEY_C], "super": [KEY_U, KEY_I, KEY_SHIFT],
		"block": [KEY_S, KEY_DOWN, KEY_L], "ok": [KEY_ENTER, KEY_KP_ENTER], "back": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in map[action]:
				var e := InputEventKey.new()
				e.physical_keycode = k
				InputMap.action_add_event(action, e)
