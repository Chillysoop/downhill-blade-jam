class_name GhostRider
extends Node3D
## Plays back a GhostTrack as a see-through copy of the skater
## (design/quick-specs/best-run-ghost-2026-11-04.md). No collision; it only
## moves when main.gd calls show_at() with the run clock.

## The recording to play (null = hidden).
var track: GhostTrack
## Seconds to fade out after the recording ends.
var fade_s: float = 0.6
var _visual: Node3D
var _mat: StandardMaterial3D
var _alpha: float = 0.4
var _snap: bool = true


## Builds the figure from [param skater]'s meshes, drawn in [param color]
## (its alpha is the ghost's see-through amount).
func setup(skater: Skater, color: Color) -> void:
	_alpha = color.a
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.emission_enabled = false
	_visual = skater.make_visual_copy(_mat)
	add_child(_visual)
	visible = false


## Shows the ghost where the recording was at run time [param t].
func show_at(t: float) -> void:
	if track == null or track.size() == 0 or _visual == null:
		visible = false
		return
	var s: Dictionary = track.sample_at(t)
	var over: float = t - track.duration()
	if over > fade_s:
		visible = false
		return
	if not visible:
		visible = true
		_snap = true
	_mat.albedo_color.a = _alpha * (1.0 - clampf(over / fade_s, 0.0, 1.0) if over > 0.0 else 1.0)
	global_position = s["pos"]
	_visual.global_basis = Basis(s["rot"] as Quaternion)
	Skater.apply_visual_pose(_visual, s["pose"])
	if _snap:
		reset_physics_interpolation()
		_snap = false
