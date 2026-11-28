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
