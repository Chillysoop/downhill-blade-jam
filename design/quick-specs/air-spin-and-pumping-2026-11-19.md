# Quick Design Spec: Air spin from takeoff, and pumping

**Type**: Tweak (new rules on existing verbs, no new buttons)
**System**: Skater movement (`src/player/skate_math.gd`, `skater.gd`, `skater_tuning.gd`)
**GDD Reference**: `design/game-brief.md` "Controls — simple and intuitive", Air and Pump lines (rigor minimal: the brief is the design record)
**Date**: 2026-11-19

## Change Summary

Conner: "semi realistic roller blading physics is critical". After the physics
audit (`skater-physics-audit-2026-11-19.md`) he picked "Both: air spin and
pumping" on 2026-11-19.

## New Rules

1. **Spin comes from the ground.** Before, steering in the air spun you at a
   fixed rate from nothing. Now the yaw rate you leave the ground with is the
   carve's turn rate, plus a wind-up when you steer as you release a charged
   jump (`air_takeoff_spin`). In the air, steering only moves the spin up to
   `air_correction_rate` (1.2 rad/s) around that, building at 4 rad/s²
   (`step_air_spin`), like arms and hips on a real skater.
2. **Pumping.** The felt ground load (`ground_load`: gravity's share plus the
   centripetal load read from how the ground normal turns under you) minus
   gravity's share is the curve load: positive in dips and banks, negative over
   crests. Moving the hips by the tuck change under that load does work:
   `v' = sqrt(v² - 2 · Δtuck · pump_leg_travel · curve_load · pump_efficiency)`.
   Standing up (Δtuck < 0) in a dip or tucking over a crest gains speed; the
   wrong timing loses it. On flat ground or a steady slope it does nothing, so
   there's no free speed from pumping on the flat.
3. **Slow off-line landings.** Below `crash_land_angle_min_speed` (4 m/s,
   14 km/h) landing turned away from travel is a step-around, not a bail. Found
   by the bot: a tight slow carve carries 60-100° into a hop. The old
   threshold was a hardcoded 2 m/s.

## Values (all in `SkaterTuning`)

| Key | Value | Why |
|---|---|---|
| `air_windup_max` | 6.0 rad/s | a 360 in about a second of air on a full charged pop |
| `air_windup_tap_share` | 0.0 | spinning is deliberate; steering through a hop line doesn't spin you |
| `air_correction_rate` / `_accel` | 1.2 rad/s / 4 rad/s² | small, as for a real skater |
| `pump_leg_travel` | 0.35 m | hip travel from full tuck to standing |
| `pump_efficiency` | 1.0 | game knob |
| `pump_load_smoothing` | 0.08 s | collision noise doesn't pump |
| `crash_land_angle_min_speed` | 4.0 m/s | replaces hardcoded 2.0 |
| `air_spin_rate` | removed | |

## Acceptance Criteria

- [x] Unit tests: takeoff spin carries the carve, wind-up needs a charge, air correction is small, ground load reads dips/crests, pumping gains only with timing and is zero on the flat, slow sideways hop is not a bail (watched failing first).
- [x] Bots finish every route; no speed above the audit's runaway threshold.
- [ ] Conner confirms it feels right (playtest).
