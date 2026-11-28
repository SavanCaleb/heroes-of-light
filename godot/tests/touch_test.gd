extends Node
## Fakes finger touches on the on-screen controls to test them (run with `-- touch touchtest`).
var t := 0.0
var steps := []
var main
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tc = _find_touch(main)
	var pad: Rect2 = tc._pad_rect()
	var right := pad.get_center() + Vector2(60, 0)
	var left := pad.get_center() - Vector2(60, 0)
	var jump: Vector2 = tc._btn("jump").c
	var atk: Vector2 = tc._btn("attack").c
	steps = [
		[0.3, "down", 0, right], [1.2, "down", 1, jump], [1.35, "up", 1, jump],
		[2.0, "down", 1, atk], [2.1, "up", 1, atk], [2.2, "down", 1, atk], [2.3, "up", 1, atk],
		[2.8, "drag", 0, left], [3.6, "drag", 0, right], [4.2, "up", 0, right],
	]
func _find_touch(n: Node):
	for c in n.get_children():
		if c.get_script() == preload("res://scripts/touch.gd"):
			return c
		var r = _find_touch(c)
		if r:
			return r
	return null
func _process(d: float) -> void:
	t += d
	while steps.size() > 0 and t >= steps[0][0]:
		var s: Array = steps.pop_front()
		var e: InputEvent
		if s[1] == "drag":
			e = InputEventScreenDrag.new()
		else:
			e = InputEventScreenTouch.new()
			e.pressed = s[1] == "down"
		e.index = s[2]
		e.position = s[3]
		Input.parse_input_event(e)
		print("t=%.2f %s finger %d  x=%.0f vx=%.0f face=%d atk=%s floor=%s" % [t, s[1], s[2], main.player.position.x, main.player.velocity.x, main.player.face, main.player.atk, main.player.is_on_floor()])
