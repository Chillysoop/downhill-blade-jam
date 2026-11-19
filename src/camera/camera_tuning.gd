class_name CameraTuning
extends Resource
## Every number that shapes the chase camera. Edited as data in
## assets/data/camera_tuning.tres, never hardcoded in ChaseCamera.
##
## Values from design/quick-specs/camera-view-height-tweak-2026-11-04.md
## (New Rules / Values), implementing brief MVP feature 6: a chase camera that
## keeps up at high speed and lets you read the slope ahead.

@export_group("Framing")
## Metres behind the skater, along the smoothed direction of travel.
@export var distance: float = 7.5
## Metres above the skater. High enough to see obstacles and lines ahead.
@export var height: float = 4.8
## Metres ahead of the skater the camera aims at: about a second ahead at speed.
@export var look_ahead: float = 16.0
## Height of the aim point above the skater, before the slope drop is added.
## 0 aims at the course rather than the sky.
@export var aim_height: float = 0.0

@export_group("Slope")
## Scales how much the aim point drops and the camera rises with the slope
## (0 = flat, old behaviour; 1 = full). Designed range 0 to 1.5.
@export_range(0.0, 1.5) var slope_follow: float = 1.0
## How fast the slope reading follows the ground, per second. Lower is
## smoother over bumps. Designed range 1 to 8.
@export_range(1.0, 8.0) var slope_sharpness: float = 3.0
## Steepest downhill grade (rise over run, negative is down) the camera
## follows. Stops wild aim on walls or near-vertical faces.
@export var grade_min: float = -1.5
## Steepest uphill grade the camera follows.
@export var grade_max: float = 0.5

@export_group("Follow")
## How fast the camera catches up with its follow position, per second.
## Also how fast it eases back out after terrain pulled it in.
@export var follow_sharpness: float = 7.0
## How fast the camera swings round to a new direction of travel, per second.
@export var turn_sharpness: float = 4.0
## Below this speed (m/s) the camera trails the skater's heading instead of
## its velocity, so it does not spin while nearly stopped.
@export var min_travel_speed: float = 2.0

@export_group("Terrain clearance")
## Gap (m) kept between the camera and terrain that pulls it in.
@export var clearance: float = 0.4
## Physics layers the camera treats as solid view-blocking world geometry.
@export_flags_3d_physics var collision_mask: int = 1

@export_group("Field of view")
## Field of view (degrees) when stopped.
@export var fov_slow: float = 70.0
## Field of view (degrees) at fov_speed_ref and above.
@export var fov_fast: float = 92.0
## Speed (m/s) at which the field of view is fully widened.
@export var fov_speed_ref: float = 35.0
## How fast the field of view follows speed changes, per second.
@export var fov_sharpness: float = 3.0
