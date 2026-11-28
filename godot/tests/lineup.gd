extends Node2D
## Test scene: every hero in a different pose, for checking the rig.
const Data := preload("res://scripts/data.gd")
const Rig := preload("res://scripts/rig.gd")
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("6aa0d8"))
	var ground := ColorRect.new()
	ground.color = Color("5cae55")
	ground.position = Vector2(0, 520)
	ground.size = Vector2(1280, 200)
	add_child(ground)
	var poses := ["idle", "run", "punch1", "kick", "jump", "cheer", "punch2", "idle"]
	for i in Data.HEROES.size():
		var r := Rig.new()
		r.setup(Data.HEROES[i].look)
		r.position = Vector2(90 + i * 150, 520)
		r.scale = Vector2(1.3, 1.3)
		r.pose = poses[i]
		add_child(r)
	var m := Rig.new()
	m.setup(Data.MINION)
	m.position = Vector2(1220, 690)
	m.face = -1
	add_child(m)
