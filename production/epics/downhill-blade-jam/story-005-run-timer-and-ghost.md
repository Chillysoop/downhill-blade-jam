# Story 005: Run timer, splits, ghost and restart

> **Epic**: Downhill Blade Jam MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 5`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief (MVP feature 5, Player goal & fail state), scoped to this story:*

- [ ] A run timer starts at the drop-in and stops when the skater crosses the finish gate
- [ ] Splits are shown at each checkpoint and compared with the personal best
- [ ] A personal-best ghost rides alongside the player
- [ ] Restart from the top is one button, any time
- [ ] Checkpoint mode and hardcore mode (a crash ends the run)

---

## Implementation Notes

Timer, splits and restart exist in `src/main.gd` and `src/ui/hud.gd`.

---

## Out of Scope

- Story 003: what counts as a crash

---

## Files

- `src/main.gd`
- `src/ui/hud.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/run/story-005-run-timer-and-ghost_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/downhill-blade-jam/story-004-open-course.md`
- Unlocks: None
