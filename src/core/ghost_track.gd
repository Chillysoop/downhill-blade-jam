class_name GhostTrack
extends RefCounted
## A recorded run for the best-run ghost (design/quick-specs/best-run-ghost-2026-11-04.md).
## Samples are taken at a fixed rate against the run clock. Each sample is the
## figure's position (3), its rotation quaternion (4) and pose_size animation
## floats (body sway/pitch/crouch and both skates, see Skater.visual_pose).

const FORMAT_VERSION: int = 1

## Samples per second of run time.
var sample_hz: float = 30.0
## Animation floats per sample after position and rotation.
var pose_size: int = 0
## Samples further apart than this (metres) snap instead of blending.
var teleport_m: float = 8.0
## The recorded run's finish time in seconds (0 = unfinished).
var finish_time: float = 0.0
## Flat sample data, stride() floats per sample, sample i at time i / sample_hz.
var data := PackedFloat32Array()


func _init(hz: float = 30.0, pose_floats: int = 0, teleport: float = 8.0) -> void:
	sample_hz = hz
	pose_size = pose_floats
	teleport_m = teleport


## Floats per sample.
func stride() -> int:
	return 7 + pose_size


## Number of recorded samples.
func size() -> int:
	return data.size() / stride()


## Run time covered by the recording, in seconds.
func duration() -> float:
	return maxf(size() - 1, 0) / sample_hz


## Drops all samples.
func clear() -> void:
	data.clear()
	finish_time = 0.0


## Records the figure at run time [param t]. Adds every sample due up to
## [param t], so a slow frame still gives evenly spaced samples.
## [param pose] must hold pose_size floats.
func record(t: float, pos: Vector3, rot: Quaternion, pose: PackedFloat32Array) -> void:
	while size() <= int(floor(t * sample_hz + 1e-4)):
		data.append_array(PackedFloat32Array([pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w]))
		for i: int in pose_size:
			data.append(pose[i] if i < pose.size() else 0.0)


## The figure at run time [param t]: {"pos", "rot", "pose", "done"}. Clamps to
## the first/last sample; "done" is true once [param t] is past the end.
func sample_at(t: float) -> Dictionary:
	var n: int = size()
	if n == 0:
		return {"pos": Vector3.ZERO, "rot": Quaternion.IDENTITY, "pose": PackedFloat32Array(), "done": true}
	var f: float = clampf(t * sample_hz, 0.0, n - 1)
	var i: int = mini(int(f), n - 1)
	var j: int = mini(i + 1, n - 1)
	var w: float = f - i
	var a: int = i * stride()
	var b: int = j * stride()
	var pa := Vector3(data[a], data[a + 1], data[a + 2])
	var pb := Vector3(data[b], data[b + 1], data[b + 2])
	if pa.distance_to(pb) > teleport_m:
		w = 0.0 if w < 0.5 else 1.0
	var qa := Quaternion(data[a + 3], data[a + 4], data[a + 5], data[a + 6]).normalized()
	var qb := Quaternion(data[b + 3], data[b + 4], data[b + 5], data[b + 6]).normalized()
	var pose := PackedFloat32Array()
	pose.resize(pose_size)
	for k: int in pose_size:
		pose[k] = lerpf(data[a + 7 + k], data[b + 7 + k], w)
	return {"pos": pa.lerp(pb, w), "rot": qa.slerp(qb, w), "pose": pose, "done": t > duration()}


## The recording as a plain Dictionary for saving.
func to_dict() -> Dictionary:
	return {"version": FORMAT_VERSION, "hz": sample_hz, "pose_size": pose_size,
		"time": finish_time, "data": data}


## Restores a recording saved with [method to_dict]. Returns null for data
## that is missing, malformed, from another format version, or has more pose
## floats than [param expected_pose_size]. Fewer (an older figure) is padded.
static func from_dict(d: Variant, expected_pose_size: int, teleport: float = 8.0) -> GhostTrack:
	if not d is Dictionary or int(d.get("version", 0)) != FORMAT_VERSION:
		return null
	var saved_pose: int = int(d.get("pose_size", -1))
	if saved_pose < 0 or saved_pose > expected_pose_size or float(d.get("hz", 0.0)) <= 0.0:
		return null
	var raw: Variant = d.get("data")
	var saved_stride: int = 7 + saved_pose
	if not raw is PackedFloat32Array or raw.size() % saved_stride != 0:
		return null
	var g := GhostTrack.new(float(d["hz"]), expected_pose_size, teleport)
	if saved_pose == expected_pose_size:
		g.data = raw
	else:
		# Older recording with fewer pose floats: pad the new ones with 0.
		var pad := PackedFloat32Array()
		pad.resize(expected_pose_size - saved_pose)
		for i: int in raw.size() / saved_stride:
			g.data.append_array(raw.slice(i * saved_stride, (i + 1) * saved_stride))
			g.data.append_array(pad)
	g.finish_time = float(d.get("time", g.duration()))
	return g


## Loads the ghost saved at [param path], or null when there is none.
static func load_file(path: String, expected_pose_size: int, teleport: float = 8.0) -> GhostTrack:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return from_dict(f.get_var(), expected_pose_size, teleport)


## Saves this recording to [param path], creating the folder if needed.
func save_file(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save ghost to %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	f.store_var(to_dict())
