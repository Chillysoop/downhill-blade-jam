# Quick Design Spec: Snappier pushes and sharper carves

**Type**: Tweak (tuning plus one formula change)
**System**: Skater movement (`src/player/skate_math.gd`, `skater_tuning.gd`)
**GDD Reference**: `design/game-brief.md` "Controls — simple and intuitive", Push / tuck line (rigor minimal: the brief is the design record)
**Date**: 2026-11-19

## Change Summary

Conner (2026-11-19, after playing): "the physics still doesn't feel real, the
acceleration is too sluggish, the turning feels not sharp enough. deeply research
inline rollerblading and make adjustments. this should feel more like SKATE games".

## Research

| Fact | Source | Population |
|---|---|---|
| Top sprinters make 14-15 W/kg for 30 s, 10-11 W/kg over 60 s | Stangier et al. 2016, J Sports Sci Med 15:41 (https://jssm.org/jssm-15-41.xml-Fulltext) | elite, literature value |
| Elite inline skaters sustain 40-50 km/h | same | elite |
| Stroke rate ~1.3/s at max effort; push-off ~200 ms | Houdijk et al. 2000, MSSE 32:635 (https://research.vu.nl/ws/files/1657479/HouKonGro%202000.pdf) | elite, ice |
| Steady recreational inline speeds 22-27 km/h | Wu et al. 2025 review, Appl Sci 15:7994 (https://www.mdpi.com/2076-3417/15/14/7994) | mixed |
| No measured lean angles or lateral g for inline carving were found | same review: curved-track studies "have not been done" | — |

So turning numbers come from physics: a balanced carve's lateral acceleration is
g·tan(lean), limited by urethane-on-concrete grip (soft outdoor wheels about 1.2-1.3).

## What was wrong (measured with the unit-test simulator)

| | Before | Real (strong skater) | After |
|---|---|---|---|
| 0 → 15 km/h on the flat | 2.7 s | ~1 s | 1.3 s |
| 0 → 20 km/h | 4.1 s | ~2 s | 2.0 s |
| 0 → 30 km/h | 10.6 s | ~4 s | ~4 s |
| Push stops helping at | 40 km/h (hard linear cut-off) | never; fades with power | power-limited, a = P/v |
| Holding W on the flat tops out at | ~32 km/h | 40-50 km/h | ~45 km/h |
| Full carve radius at 30 km/h | 6.8 m | ~6 m | 5.9 m |
| Full carve while tucked at 50 km/h | 49 m (0.4 g) | ~25-30 m | 27 m |
| Edge to full lean | 0.18 s | quick | 0.15 s |
| Pivot when nearly stopped | 1.8 rad/s | quick footwork | 3.0 rad/s |

## Bug found on the way: wheels lifting off on every uphill roll

Rolling up any slope (a carve that swings uphill, the far side of a dip, a
bank) put the skater in the air every other physics frame: Godot's
`move_and_slide` skips the floor snap whenever velocity points even slightly
up, and the wheels sat 1-2 mm above the ground. In those frames there was no
steering, no push and no grip, so carves across or up a slope felt mushy and
pumping lost its load reading. Fix: while grounded, if the move left the
skater off the floor, `apply_floor_snap()` (same snap reach as before, so
stairs, curbs and crests still launch you). Regression test
`tests/integration/skater/test_skater_ground_contact.gd` failed on the old code
(31 of 60 frames airborne rolling straight uphill) and passes now.

## Rules / Values

- `SkateMath.stride_accel`: `min(stride_peak_accel, stride_power / (v · duty)) · pulse`,
  where `duty = stride_push_share · 2/π`. Average push = `min(peak · duty, P / v)`.
  `stride_max_speed` removed.
- New `stride_power` 10 W/kg. `stride_peak_accel` 5.5 → 7.4. `stride_push_share` 0.6 → 0.7.
- `lean_max_deg` 46 → 50, `lean_max_tuck_deg` 22 → 36, `lean_rate_deg` 260 → 340.
- `side_grip` 1.05 → 1.25 (grip fade above 43 km/h unchanged, so full lock at high speed still washes wide).
- `min_turn_radius` 1.6 → 1.2, `pivot_turn_rate` 1.8 → 3.0.
- Stride/tuck switch (unchanged rule) now falls at about 60 km/h, because pushes keep helping.

## Acceptance Criteria

- [x] Unit tests `test_stride_takeoff_is_realistic`, `test_carves_are_sharp`, `test_tucked_carves_still_turn`, `test_lean_is_quick` and the sprint-start push check fail on the old values (watched: 10 failures) and pass now.
- [x] Bots finish their routes (see evidence).
- [x] Rolling or carving uphill keeps the wheels down (integration test, watched failing).
- [ ] Conner confirms it feels snappy and real (playtest).
