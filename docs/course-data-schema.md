# Course Data Schema (`assets/data/course_*.json`)

One JSON file describes one course. `CourseBuilder` (`src/levels/course/`) reads it:
`CourseTerrain` turns the `terrain` block into a height grid and a surface grid,
`CourseKit` builds every entry in `features`, and the builder adds `gates`.
Units are metres. **Downhill is −Z**, X runs across the slope (+X = east/right
looking downhill), Y is up. Points are `[x, z]`. Curves are lists of
`[z, value]` knots, interpolated with a smooth monotone cubic and clamped at the ends.

First course: `assets/data/course_copperline_mountain.json`, designed in
`design/levels/copperline-mountain.md` (§2.4 terrain, §2.7 skips, §2.11 sizes).

## Top level

| Key | Type | Meaning |
|---|---|---|
| `name` | string | Display name |
| `schema_version` | int | Bump on breaking changes (now 1) |
| `design` | string | Path of the level design doc this file implements |
| `spawn` | point | Start position; the skater faces down the fan axis |
| `out_of_bounds_u` | float | Beyond this across-fan value (±1 = fan edge) you are out of bounds (default 1.25) |
| `surfaces` | object | Off-piste drag per surface: `grass`, `gravel` → `{drag_v2` (1/m, × speed²), `rolling` (m/s²), `min_speed` (m/s, no drag below it so pushing always moves you)}`. Concrete and rock have none |
| `terrain` | object | Ground, below |
| `gates` | list | Checkpoints and finish, below |
| `features` | list | Placed kit pieces, below |
| `routes` | object | Name → list of points; used only by the dev autopilot (`-- --route=<name>`) |

## `terrain`

| Key | Meaning |
|---|---|
| `seed` | Noise seed (same seed = same mountain) |
| `grid` | `cell` (m), `x_min`, `x_max`, `z_max`, `z_min`, `chunk_cells` (mesh/collision tile size in cells) |
| `base` | Curve: base height along the fall line (before the cliff steps) |
| `axis` | Curve: X of the fan's centre line |
| `width` | Curve: full fan width |
| `crown` | Curve: how much higher the fan's centre is than its edges (convex fan) |
| `tilt` | Curve: cross-slope in degrees (+ = west side lower) so the fall line twists |
| `noise` | `large_amp`/`large_wavelength`, `small_amp`/`small_wavelength` (m) |
| `margin` | Valley walls past the fan edge: `wall_deg`, `cap` (max height), `wander`/`wander_wavelength` (edge wobble), `rock_above` (wall turns to rock above this height) |
| `rock_slope_deg` | Anything steeper is painted rock (it is also a wall to the skater) |
| `concrete_zones` | Whole-width concrete bands: `z_from`, `z_to`, `u_limit` |
| `bands` | Concrete paint along a spline: `points`, `width`, optional `wander`, `keep` (surfaces it won't paint over; default gravel and rock) |
| `channels` | Carved concrete strands: `points`, `width`, `depth`, `floor_frac` (flat share of the width), `wander`, `taper`/`taper_in`/`taper_out` (depth fades in/out over this length), `rim_width`/`rim_surface` |
| `islands` | Raised ellipses: `x`, `z`, `rx`, `rz`, `yaw`, `height` (negative digs a trough), `edge` (flank width; steep flanks become rock), `top`, `flank` surfaces |
| `islet_fields` | Seeded scatter of small islands: region (`z_from`, `z_to`, `u_from`, `u_to`), `count`, size ranges, `min_gap`, `clearance`, `avoid_lines`, `avoid_circles` |
| `bars` | Raised strips along a spline: `points`, `height`, `edge`, `widths` (`[x, width]` knots), `surface`, `cuts` (`x`, `width`, `flare`: concrete gaps through the bar) |
| `steps` | Cliff bands and drop lips. A wavy line `z` + `wave_amp`·sin(2πx/`wave_length`); ground below it drops by each x-zone's `profile` of `[s, drop]` (s = metres below the line, negative = above it). `extends_down` keeps the full drop to the bottom of the map; otherwise the profile must return to 0. Zones may set `surface` between `surface_from` and `surface_to` |

Surfaces: `concrete` (fast), `grass` (slow), `gravel` (slow), `rock` (crash faces).
Stamp order: base → bands → channels → islands → islets → bars → steps → steepness.

## `gates`

`name`, `z`, `pads` (respawn X positions; a crash returns you to the pad
nearest where you crossed, 15 m below the gate, clock still running),
optional `kind: "finish"` with `arch_x`. Gates are full-width planes and count in order.

## `features` (the shared level kit)

Every entry has `type` and an `id` (for people; not read by code).
Facing: `heading` (degrees, 0 = straight down −Z, + turns toward +X) or
`toward` (a point); default is down the fan axis.

| `type` | Keys | Notes |
|---|---|---|
| `ramp` | `a`, `b`, `lift_a`, `lift_b`, `width`, `thickness`, `kind`, `plane` | Slab whose top runs from a to b. Landings, drop-ins |
| `kicker` | `at`, facing, `width`, `length`, `height`, `kind` (default `concrete`) | Launch ramp |
| `stairs` | `at`, facing, `count`, `rise`, `tread`, `width`, `overlap` | Step-ups; the top step is `count × rise` above a plane that follows the base slope, so it meets an island of that height |
| `deck` | `a`, `b`, `lift_a`, `drop`, `width`, `rails` (`[{side}]`), `pillar_spacing` | Elevated trestle on pillars |
| `box` | `at`, facing, `size` (across, height, along), `lift`, `kind`, `collide` | Buildings, roofs, arches |
| `cylinder` | `at`, `radius`, `top_radius` (cone), `height`, `lift`, `kind`, `collide` | Spires, masts |
| `rail` | `a`, `b`, `lift`, `kind` | Grind rail on posts (geometry until grinding exists) |
| `boulders` | `at`, `radius`, `count`, `size_min`, `size_max`, `seed`, `kind` | Crash rocks |
| `trees` | `at`, `radius`, `count`, `seed` **or** `margin: {z_from, z_to, u_from, u_to, spacing}` | Trees are crash obstacles |
| `markers` | `points`, `kind` (strand colour), `shape` (`round`, `square`, `pennant`), `offset`, `spacing` | Strand poles; visual only. **Not used**: lines are unmarked (design/levels/copperline-mountain.md §3.2) |
| `chairlift` | `points`, `offset`, `spacing`, `height` | Towers (solid) and cables |

`kind` picks a colour from the shared colour language in `CourseKit.colors`
(red `hazard` = crash, green/white = checkpoint). Route hints such as yellow `skip` paint are not used; see the level design §3.2.
