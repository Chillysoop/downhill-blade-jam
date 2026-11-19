# Story 006: Chase camera that reads the slope ahead

> **Epic**: Downhill Blade Jam MVP
> **Status**: In Progress
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 6`
**Quick Spec**: `design/quick-specs/camera-view-height-tweak-2026-11-04.md` (approved by Conner 2026-11-04)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief, MVP feature 6 ("A chase camera that keeps up at high speed and lets you read the slope ahead"), made concrete by the quick spec:*

- [ ] Camera values are read from `assets/data/camera_tuning.tres` (a `CameraTuning` resource), not hardcoded
- [ ] The camera follows 7.5 m behind and 4.8 m above the skater and aims 16 m ahead along the direction of travel
- [ ] The aim point drops with the slope ahead (smoothed ground grade while grounded), so on a downhill the course ahead stays in frame and the horizon sits above the middle of the screen
- [ ] The camera holds its slope tilt while airborne or crashed: no swing during jumps
- [ ] On Copperline Mountain the camera never ends up inside a valley wall, channel side or cliff band (it moves in when terrain blocks the view)
- [ ] Respawn and restart snap the camera straight to the new position
- [ ] No regression: the camera still follows turns smoothly and FOV still widens with speed

---

## Implementation Notes

See the quick spec's Design Delta and New Rules / Values for the exact rules and numbers.

---

## Out of Scope

- Story 001: skater movement itself
- Story 004: course geometry
- Story 005: HUD and timer

---

## Files

- `src/camera/chase_camera.gd`
- `src/camera/camera_tuning.gd`
- `assets/data/camera_tuning.tres`
- `src/main.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory), but this Visual/Feel story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/story-006-chase-camera-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-006-chase-camera-evidence.md` (sign-off pending)

---

## Dependencies

- Depends on: None
- Unlocks: None
