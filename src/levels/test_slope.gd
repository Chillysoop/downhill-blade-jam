class_name TestSlope
extends LevelBuilder
## Greybox movement test slope. Each segment exercises one skill:
## kickers, rollers, hop curbs, a step-up to a gap shortcut, a narrow channel,
## a big kicker on the steep, then a runout with the finish gate.

## Where the skater starts.
var spawn_point: Vector3
## Downhill direction at the start.
var spawn_facing: Vector3
## The finish trigger.
var finish: Area3D


func _ready() -> void:
	const W: float = 32.0
	# 0: start pad
	var s0: int = add_segment(14.0, 3.0, W)
	# 1: warm-up with small kickers and a few trees
	var s1: int = add_segment(60.0, 12.0, W)
	kicker(s1, -6.0, 16.0, 5.0, 4.0, 14.0)
	kicker(s1, 7.0, 30.0, 5.0, 4.0, 18.0)
	for p: Vector2 in [Vector2(-12, 26), Vector2(12, 12), Vector2(2, 44), Vector2(-9, 50)]:
		tree(s1, p.x, p.y)
	# 2: rollers to hop off the top of, and hop curbs down the middle
	var s2: int = add_segment(50.0, 15.0, W)
	for i: int in 3:
		roller(s2, -9.0, 8.0 + i * 12.0, 12.0, 1.0, 6.0)
	for i: int in 5:
		box(s2, 7.0, 8.0 + i * 7.0, Vector3(12.0, 0.4, 1.0), "ledge")
	# 3: step-up shortcut on the left over a pit; tree slalom on the right
	var pit_s0: float = 25.0
	var pit_s1: float = 42.0
	var s3: int = add_segment(50.0, 8.0, W, [[-W / 2.0, -1.0, pit_s0, pit_s1]])
	step_up(s3, -8.5, 4.0, 13.0, 3, 0.55, 3.0, 12.0)
	kicker(s3, -8.5, 21.0, 13.0, 3.5, 16.0)
	box(s3, -1.0 + 0.4, 37.0, Vector3(0.8, 1.6, 26.0), "wall")
	for i: int in 6:
		tree(s3, 5.0 + (i % 2) * 7.0, 10.0 + i * 6.0)
	# 4: narrow channel through the middle, bumpy rollers outside it
	var s4: int = add_segment(60.0, 15.0, W)
	for side: float in [-1.0, 1.0]:
		box(s4, side * 3.4, 30.0, Vector3(0.8, 1.6, 50.0), "wall")
		for i: int in 4:
			roller(s4, side * 10.5, 10.0 + i * 11.0, 10.0, 0.7, 4.0)
	# 5: steep with a big kicker
	var s5: int = add_segment(40.0, 20.0, W)
	kicker(s5, 0.0, 14.0, 8.0, 6.0, 18.0)
	# 6: runout and finish
	var s6: int = add_segment(60.0, 4.0, W)
	finish = finish_gate(s6, 30.0)
	box(s6, 0.0, 59.5, Vector3(W, 3.0, 1.0), "berm")

	spawn_point = surface_point(s0, 0.0, 5.0) + Vector3(0, 0.3, 0)
	spawn_facing = segment_dir(s1) * Vector3(1, 0, 1)
