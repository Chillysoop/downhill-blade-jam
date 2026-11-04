class_name SkaterTuning
extends Resource
## Every number that shapes how the skater feels. Edited as data in
## assets/data/skater_tuning.tres, never hardcoded in the controller.
##
## Defaults are grounded in real inline skating (design/game-brief.md,
## "Core Mechanics"): real gravity, an 80 kg skater's air drag, urethane wheel
## grip, real stride, brake and landing behaviour. Where a value is a game
## choice rather than a measurement, its comment says so.

@export_group("World")
## Gravity in m/s². Real Earth gravity.
@export var gravity: float = 9.81

@export_group("Rolling")
## Rolling resistance as a fraction of gravity. Urethane wheels on smooth
## asphalt are about 0.006-0.01.
@export var rolling_resistance: float = 0.008
## Air drag standing up, as 0.5 * air density * CdA / mass, per metre.
## 0.5 * 1.2 * 0.55 m² / 80 kg. Sets top speed on a slope.
@export var drag: float = 0.0041
## Air drag in a tuck (CdA about 0.3 m²). Lower drag means a higher top speed.
@export var drag_tuck: float = 0.00225
## Air drag while airborne (body extended, same as standing).
@export var air_drag: float = 0.0041
## Holding forward below this speed (m/s) strides; above it, it tucks.
@export var tuck_speed: float = 7.5

@export_group("Striding")
## Seconds per push stroke (one leg). Real recreational cadence is ~0.6-0.8 s.
@export var stride_period: float = 0.65
## Share of each stroke spent pushing; the rest is the glide and recovery.
@export var stride_push_share: float = 0.6
## Peak push acceleration (m/s²) from a standstill, at the middle of a push.
@export var stride_peak_accel: float = 5.5
## Speed (m/s) at which a push stops helping: the foot can't push faster than
## the ground moves under it. About 32 km/h for a strong skater on the flat.
@export var stride_max_speed: float = 9.0

@export_group("Carving")
## Steepest lean onto the edges (degrees) at full steer. A balanced carve
## turns with lateral g = tan(lean), so 45° is a 1 g carve.
@export var lean_max_deg: float = 45.0
## Steepest lean while tucked; a tuck only allows gentle carves.
@export var lean_max_tuck_deg: float = 22.0
## How fast the body rolls onto its edges, degrees per second.
@export var lean_rate_deg: float = 260.0
## Sideways grip of the wheels as a friction coefficient (urethane: ~0.9-1.1).
## Asking for more turn than this makes the skates slide.
@export var side_grip: float = 1.05
## Speed lost to wheel scrub while carving, as a share of the lateral g.
## Sharper turns cost more speed.
@export var carve_scrub: float = 0.04
## Tightest turning circle radius (m) the frame allows at low speed.
@export var min_turn_radius: float = 1.6
## Turn rate (rad/s) when nearly stopped, by stepping the skates around.
@export var pivot_turn_rate: float = 1.8

@export_group("Braking")
## T-stop deceleration (m/s²): the trailing skate dragged sideways behind the
## front one. Real T-stops manage about 0.3-0.4 g.
@export var t_stop_decel: float = 3.4
## Above this speed (m/s) the T-stop drags harder: weight goes onto the
## trailing skate and its wheels slide instead of just scrubbing.
@export var hard_brake_speed: float = 6.0
## Hard T-stop deceleration (m/s²) above hard_brake_speed, wheels sliding.
## About 0.6 g.
@export var hard_brake_decel: float = 6.0
## Share of steering available while hard braking.
@export var hard_brake_steer_mult: float = 0.3
## Braking after crossing the finish (not player braking), m/s². A game value
## so runs stop before the end wall.
@export var auto_brake_decel: float = 12.0

@export_group("Jumping")
## Pop speed (m/s) for a tap of jump. 3.4 m/s is a ~0.6 m hop, enough to
## clear a curb or one stair of a step-up.
@export var pop_min: float = 3.4
## Pop speed (m/s) for a fully charged jump. 4.8 m/s is a ~1.2 m jump.
@export var pop_max: float = 4.8
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

@export_group("Landing")
## Share of the into-ground impact speed that is also lost from rolling speed
## as the wheels bite on touchdown. Landing on a downslope keeps speed;
## landing flat from high up bleeds it.
@export var landing_friction: float = 0.12
## Landing with the skates within this many degrees of the travel direction
## straightens them out onto it, as feet do on touchdown. Further off, the
## sideways part of the speed is scrubbed away by wheel grip.
@export var landing_align_deg: float = 20.0
## Impact speeds (m/s into the ground) the knees soak up without a visible
## stomp. About a 0.8 m drop to flat.
@export var landing_soft_impact: float = 4.0

@export_group("Crashing")
## Landing with the skates this far (degrees) off the travel direction is a bail.
@export var crash_land_angle_deg: float = 60.0
## Hitting the ground faster than this (m/s, into the surface) is a bail.
## 11 m/s is a ~6 m drop to flat, about the most legs and pads can take.
@export var crash_land_impact: float = 11.0
## Hitting a wall or obstacle faster than this (m/s, head-on part) is a bail.
@export var crash_wall_speed: float = 9.0
## Seconds spent tumbling before respawning.
@export var respawn_delay: float = 1.4
## Slide friction while tumbling, m/s².
@export var crash_friction: float = 9.0
