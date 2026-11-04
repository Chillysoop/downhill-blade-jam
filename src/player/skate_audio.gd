class_name SkateAudio
extends Node
## Wheel sound, synthesised live so the player can hear what the wheels are
## doing (design/game-brief.md "Controls"): a hum that rises with speed, a
## screech as the carve nears the grip limit or the skates slide, and a
## scrape while braking. Also rumbles a connected gamepad near the limit.

## The skater to listen to. Set before adding to the tree.
var skater: Skater
## Overall volume (linear, 0..1).
@export var volume: float = 0.8
## Speed (m/s) at which the wheel hum is at full volume.
@export var hum_full_speed: float = 25.0

const MIX_RATE: float = 22050.0

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _lp_hum: float = 0.0
var _lp_hi: float = 0.0
var _hp_prev: float = 0.0
var _lp_scr: float = 0.0
var _hum: float = 0.0
var _screech: float = 0.0
var _scrape: float = 0.0
var _freq: float = 0.0
var _rumble_t: float = 0.0
var _rng := RandomNumberGenerator.new()


## How close a carve is to sliding, as 0 (plenty of grip) to 1 (at or past the
## limit), from the skater's grip usage. Drives the screech and the stance.
static func edge_level(grip_usage: float) -> float:
	return clampf((grip_usage - 0.85) / 0.15, 0.0, 1.0)


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.1
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = linear_to_db(maxf(volume, 0.0001))
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_rng.seed = 1


func _process(dt: float) -> void:
	if skater == null or _playback == null:
		return
	var grounded: bool = skater.state == Skater.State.GROUNDED
	var speed: float = skater.get_speed()
	var edge: float = edge_level(skater.grip_usage) if grounded else 0.0
	var target_hum: float = clampf(speed / hum_full_speed, 0.0, 1.0) * (1.0 if grounded else 0.0)
	var target_screech: float = edge * clampf(speed / 8.0, 0.0, 1.0)
	var target_scrape: float = (1.0 if skater.t_stopping else 0.0) * clampf(speed / 6.0, 0.2, 1.0)
	var k: float = 1.0 - exp(-12.0 * dt)
	_hum = lerpf(_hum, target_hum, k)
	_screech = lerpf(_screech, target_screech, k)
	_scrape = lerpf(_scrape, target_scrape, k)
	# Wheel spin: 76 mm wheels turn at v / (pi * 0.076) rev/s.
	_freq = lerpf(_freq, speed / (PI * 0.076) * 0.25 + 30.0, k)
	_fill()
	_rumble(edge, dt)


func _fill() -> void:
	var frames: int = _playback.get_frames_available()
	var hum_cut: float = clampf(0.02 + _hum * 0.08, 0.0, 1.0)
	for i: int in frames:
		var noise: float = _rng.randf_range(-1.0, 1.0)
		_lp_hum += (noise - _lp_hum) * hum_cut
		_phase = fmod(_phase + _freq / MIX_RATE, 1.0)
		var hum: float = (_lp_hum * 1.6 + sin(TAU * _phase) * 0.35) * _hum * 0.5
		# Screech: noise high-passed then softened, a hiss around 2-4 kHz.
		var hp: float = noise - _hp_prev
		_hp_prev = noise
		_lp_scr += (hp - _lp_scr) * 0.55
		var wail: float = sin(TAU * _phase * 23.0) * 0.3
		var screech: float = (_lp_scr + wail) * _screech * 0.35
		# Brake scrape: a rougher mid-band hiss.
		_lp_hi += (noise - _lp_hi) * 0.25
		var scrape: float = (_lp_hi - _lp_hum) * _scrape * 0.6
		var v: float = clampf(hum + screech + scrape, -1.0, 1.0)
		_playback.push_frame(Vector2(v, v))


func _rumble(edge: float, dt: float) -> void:
	_rumble_t -= dt
	if _rumble_t > 0.0:
		return
	_rumble_t = 0.1
	for pad: int in Input.get_connected_joypads():
		if edge > 0.0:
			Input.start_joy_vibration(pad, 0.3 * edge, 0.6 * edge * edge, 0.15)
