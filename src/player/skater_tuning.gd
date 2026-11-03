class_name SkaterTuning
extends Resource
## Every number that shapes how the skater feels. Edited as data in
## assets/data/skater_tuning.tres, never hardcoded in the controller.

@export_group("World")
## Gravity in m/s². Higher than real life for snappier, less floaty jumps.
@export var gravity: float = 18.0

@export_group("Rolling")
## Rolling resistance as a fraction of gravity (wheel friction).
@export var rolling_resistance: float = 0.015
## Air drag coefficient when standing upright. Sets top speed on a slope.
@export var drag: float = 0.006
## Air drag coefficient while tucked. Lower drag means a higher top speed.
@export var drag_tuck: float = 0.0035
## Holding forward below this speed (m/s) pushes (skates strides) instead of tucking.
@export var push_max_speed: float = 9.0
## Acceleration from pushing, m/s².
@export var push_accel: float = 7.0
## Braking deceleration, m/s².
@export var brake_decel: float = 14.0

@export_group("Steering")
## Turn rate (rad/s) when nearly stopped.
@export var turn_rate_slow: float = 2.8
## Turn rate (rad/s) at turn_rate_speed_ref and above.
@export var turn_rate_fast: float = 1.2
## Speed (m/s) at which turning reaches its slowest rate.
@export var turn_rate_speed_ref: float = 32.0
## Steering multiplier while tucked.
@export var tuck_steer_mult: float = 0.55
## How quickly sideways sliding is cancelled by wheel grip (per second).
@export var grip: float = 9.0
## Share of cancelled sideways speed that is kept as forward speed (carving).
@export var carve_efficiency: float = 0.88

@export_group("Jumping")
## Pop speed (m/s) for a tap of jump.
@export var pop_min: float = 4.5
## Pop speed (m/s) for a fully charged jump.
@export var pop_max: float = 8.0
## Seconds to fully charge a jump.
@export var charge_time: float = 0.45
## Seconds after leaving the ground in which a jump still pops (lip ollies).
@export var coyote_time: float = 0.12
## Releasing jump this many seconds before touching down pops again on landing,
## so hops chain into combos.
@export var hop_buffer_time: float = 0.15

@export_group("Air")
## Spin rate (rad/s) when steering in the air.
@export var air_spin_rate: float = 4.0
## Air drag while airborne (lighter than on the ground).
@export var air_drag: float = 0.002

@export_group("Crashing")
## Landing with the skates this far (degrees) off the travel direction is a bail.
@export var crash_land_angle_deg: float = 65.0
## Hitting the ground faster than this (m/s, into the surface) is a bail.
@export var crash_land_impact: float = 24.0
## Hitting a wall or obstacle faster than this (m/s, head-on part) is a bail.
@export var crash_wall_speed: float = 9.0
## Seconds spent tumbling before respawning.
@export var respawn_delay: float = 1.4
## Slide friction while tumbling, m/s².
@export var crash_friction: float = 9.0
