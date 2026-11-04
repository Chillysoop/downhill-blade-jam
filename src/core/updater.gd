extends CanvasLayer
## Self-updater for the Windows build. On start it asks the latest-build
## GitHub release which commit it holds; if that differs from this build it
## downloads the new game, swaps the executable and restarts. Any failure
## (offline, GitHub down) just lets the current build play.
##
## Skipped in the editor, on non-Windows platforms, for local "dev" builds,
## and when started with the user arg --no-update.

const RELEASE_URL: String = "https://github.com/Chillysoop/downhill-blade-jam/releases/download/latest-build/"
const ID_ASSET: String = "build-id.txt"
const ZIP_ASSET: String = "DownhillBladeJam-windows.zip"
const EXE_IN_ZIP: String = "DownhillBladeJam.exe"

var _http: HTTPRequest
var _label: Label
var _zip_path: String
var _downloading: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_cleanup_old_exe()
	if not _should_check():
		return
	_build_overlay()
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_id_received)
	if _http.request(RELEASE_URL + ID_ASSET) != OK:
		_finish("could not start update check")


func _should_check() -> bool:
	if OS.has_feature("editor") or not OS.has_feature("windows"):
		return false
	if BuildId.SHA == "dev":
		return false
	return not OS.get_cmdline_user_args().has("--no-update")


func _on_id_received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.request_completed.disconnect(_on_id_received)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish("update check failed (%d/%d)" % [result, code])
		return
	var latest: String = body.get_string_from_utf8().strip_edges()
	if latest.is_empty() or latest == BuildId.SHA:
		_finish("up to date (%s)" % BuildId.SHA)
		return
	print("Updater: %s -> %s" % [BuildId.SHA, latest])
	get_tree().paused = true
	_label.visible = true
	_label.text = "Updating to the newest build..."
	_zip_path = OS.get_user_data_dir().path_join("update.zip")
	_http.download_file = _zip_path
	_http.timeout = 600.0
	_http.request_completed.connect(_on_zip_received)
	_downloading = true
	if _http.request(RELEASE_URL + ZIP_ASSET) != OK:
		_finish("could not start download")


func _process(_dt: float) -> void:
	if _downloading and _http != null:
		var total: int = _http.get_body_size()
		var got: int = _http.get_downloaded_bytes()
		if total > 0:
			_label.text = "Updating to the newest build...  %d%%" % int(100.0 * got / total)


func _on_zip_received(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_downloading = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish("download failed (%d/%d)" % [result, code])
		return
	_label.text = "Installing update..."
	await get_tree().process_frame
	var err: String = _install(_zip_path)
	DirAccess.remove_absolute(_zip_path)
	if err != "":
		_finish(err)
		return
	OS.create_process(OS.get_executable_path(), [])
	get_tree().quit()


## Replaces the running executable with the one in the downloaded zip.
## Windows allows renaming a running .exe, so the old one is moved aside and
## deleted on the next start. Returns "" on success, or an error message.
func _install(zip_path: String) -> String:
	var zip := ZIPReader.new()
	if zip.open(zip_path) != OK:
		return "downloaded update is not a valid zip"
	var data: PackedByteArray = zip.read_file(EXE_IN_ZIP)
	zip.close()
	if data.size() < 1_000_000:
		return "downloaded update is missing the game"
	var exe: String = OS.get_executable_path()
	var old: String = exe + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)
	if DirAccess.rename_absolute(exe, old) != OK:
		return "could not move the old game aside"
	var f := FileAccess.open(exe, FileAccess.WRITE)
	if f == null or not f.store_buffer(data):
		if f != null:
			f.close()
		DirAccess.rename_absolute(old, exe)
		return "could not write the new game"
	f.close()
	return ""


func _cleanup_old_exe() -> void:
	if OS.has_feature("editor"):
		return
	var old: String = OS.get_executable_path() + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)


func _finish(msg: String) -> void:
	print("Updater: ", msg)
	_downloading = false
	get_tree().paused = false
	if _label != null:
		_label.visible = false


func _build_overlay() -> void:
	_label = Label.new()
	_label.visible = false
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 40)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 10)
	add_child(_label)
