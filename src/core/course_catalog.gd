class_name CourseCatalog
extends RefCounted
## The list of playable courses, read from assets/data/courses.json. Each entry
## is a Dictionary with "id", "name", "path" (a course JSON, or "test_slope")
## and "blurb". Map select shows them in file order; the first is the default.

const DEFAULT_PATH: String = "res://assets/data/courses.json"

## The parsed course entries, in display order.
var courses: Array[Dictionary] = []


## Builds a catalog from already-parsed JSON data. Entries without an id or a
## path are skipped; a missing name falls back to the id.
static func from_dict(data: Dictionary) -> CourseCatalog:
	var cat := CourseCatalog.new()
	for raw: Variant in data.get("courses", []):
		if not raw is Dictionary:
			continue
		var e: Dictionary = raw
		var id: String = String(e.get("id", ""))
		var path: String = String(e.get("path", ""))
		if id.is_empty() or path.is_empty():
			continue
		cat.courses.append({
			"id": id,
			"name": String(e.get("name", id)),
			"path": path,
			"blurb": String(e.get("blurb", "")),
		})
	return cat


## Reads and parses the catalog file at [param path].
static func load_file(path: String = DEFAULT_PATH) -> CourseCatalog:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(parsed if parsed is Dictionary else {})


## The entry with [param id], or the first entry when there is no match
## (empty Dictionary when the catalog is empty).
func find(id: String) -> Dictionary:
	for e: Dictionary in courses:
		if e["id"] == id:
			return e
	return courses[0] if not courses.is_empty() else {}


## The entry whose data path is [param path], or an empty Dictionary.
func find_by_path(path: String) -> Dictionary:
	for e: Dictionary in courses:
		if e["path"] == path:
			return e
	return {}
