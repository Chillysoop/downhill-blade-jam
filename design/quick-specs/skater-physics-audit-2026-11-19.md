# Quick Design Spec: Skater physics audit (wharf, stairs, runaway speed)

**Type**: Tweak (plus a bug fix)
**System**: Skater movement (`src/player/skate_math.gd`, `skater.gd`, `skater_tuning.gd`)
**GDD Reference**: `design/game-brief.md` "Controls — simple and intuitive" (rigor minimal: the brief is the design record)
**Date**: 2026-11-19

## Change Summary

Conner (2026-11-04): "physics is wonky, needs to be more realistically accurate to
rollerblading. On the SF level there is tucking on the flat on the wharf and no
sense of momentum / acceleration / skating. There are stairs that the model angles
down instead of launching off. Do a deepdive into physics." He resumed the work
on 2026-11-19.

## Findings (reproduced with the test bot on Hillcrest Drop)

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | Speed kept *rising* on the flat Bayfront, reaching 192 km/h; the run felt like it had no momentum because speed never related to the hill | Bug from the 2026-11-04 wheel-feel pass: the "seam" filter (ignore a floor normal that jumps >30°) could lock in a steep normal picked up on a stair edge. Every real flat normal then looked like a seam, so gravity kept pulling along a 45° slope that wasn't there | The ground normal now comes from a ray straight down onto the face under the wheels, and a flatter normal is never treated as a seam, so a stale steep normal can't stick |
| 2 | Tucking on the flat wharf, no skating | Holding W tucked above a fixed 27 km/h on any slope | W now strides while a push adds more speed than a tuck's lower drag would save, and tucks once it doesn't (about 36 km/h, with a small hysteresis so it doesn't flicker). On the flat you keep skating at ~32 km/h |
| 3 | Rolling *along* stairs instead of launching | Floor snap of 0.45 m glued the skater down each 18 cm step | Snap is now what gravity pulls you down in one physics step plus 4 cm of leg reach. Ground that drops away faster (a stair edge, a curb, a sharp crest at speed) launches you |

## New Rules / Values

- `stride_tuck_hysteresis` 0.15 (new). `tuck_speed` removed.
- `stride_max_speed` 9 → 11 m/s (a strong skater pushes to about 40 km/h on the flat).
- `snap_absorb` 0.04 m (new). Snap = `snap_absorb + 0.5 * g * dt²`.
- `SkateMath.is_seam_normal`: false whenever the new normal is flatter than the old one.
- `SkateMath.prefer_stride(speed, tucking)`: stride when `stride_avg_accel(speed) > (drag - drag_tuck) * speed²` (times 1 ± hysteresis).
- Skater ground normal: ray down from 0.4 m above the skater's feet to 0.6 m below; falls back to the collider's floor normal.

## Affected Systems

| System | Impact | Action Required |
|---|---|---|
| Hillcrest Drop | Real speeds now: ~45 km/h tucked on the 3% lower streets (was 190). Stairs at walking speed drop flight by flight (slow, bumpy, as the level doc intends); bot finishes the House route in 1:36.19 | Level thread may want to retune targets |
| Copperline Mountain | Bot times change because the runaway also happened there after stair/edge contacts | Bot route times re-measured below |
| Test Slope | Unchanged behaviour on clean geometry | none |

## Acceptance Criteria

- [x] On the flat Bayfront, holding W keeps you striding at a steady ~32 km/h; speed never rises on flat ground (bot telemetry, 2026-11-19).
- [x] The Hillcrest Steps at slow speed drop you down flight by flight in the air, not glued along the stair line.
- [x] A stale steep normal cannot persist (regression test `test_flatter_normal_is_never_a_seam`, watched failing against the old code).
- [x] Unit suites pass.
- [ ] Conner confirms it feels like skating (playtest).

## GDD Update Required?

Yes: `design/game-brief.md` Controls, "Push / tuck" line (updated in the same commit).
