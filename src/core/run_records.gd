class_name RunRecords
extends RefCounted
## Personal bests per course: best finish time and the splits of that run.
## The logic works on an in-memory Dictionary; load_file/save_file persist it
## (the game uses user://records.cfg) so bests survive closing the game.

const DEFAULT_PATH: String = "user://records.cfg"

## course id -> {"best": float seconds, "splits": Array[float]}
var data: Dictionary = {}


## Best finish time on [param course_id] in seconds, or 0.0 when none is set.
func best_time(course_id: String) -> float:
	return float(data.get(course_id, {}).get("best", 0.0))


## Split times of the best run on [param course_id] (empty when none).
func best_splits(course_id: String) -> Array[float]:
	var out: Array[float] = []
	for s: Variant in data.get(course_id, {}).get("splits", []):
		out.append(float(s))
	return out


## Smallest improvement that counts as a new best: the clock shows hundredths,
## so a run that reads the same as the best is not a new one.
const TIE_EPSILON_S: float = 0.005


## True when [param time_s] beats the current best (or there is none yet).
func is_new_best(course_id: String, time_s: float) -> bool:
	var best: float = best_time(course_id)
	return time_s > 0.0 and (best <= 0.0 or time_s < best - TIE_EPSILON_S)


## Records a finished run. Returns true and stores it when it is a new best.
func submit(course_id: String, time_s: float, splits: Array[float]) -> bool:
	if not is_new_best(course_id, time_s):
		return false
	data[course_id] = {"best": time_s, "splits": splits.duplicate()}
	return true


## Loads records from [param path]; a missing or unreadable file leaves none.
func load_file(path: String = DEFAULT_PATH) -> void:
	data.clear()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for id: String in cfg.get_sections():
		data[id] = {
			"best": float(cfg.get_value(id, "best", 0.0)),
			"splits": cfg.get_value(id, "splits", []),
		}


## Writes all records to [param path].
func save_file(path: String = DEFAULT_PATH) -> void:
	var cfg := ConfigFile.new()
	for id: String in data:
		cfg.set_value(id, "best", data[id]["best"])
		cfg.set_value(id, "splits", data[id]["splits"])
	var err: Error = cfg.save(path)
	if err != OK:
		push_warning("Could not save records to %s (error %d)" % [path, err])
