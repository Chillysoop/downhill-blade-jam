# Story 003: Fair crash rules

> **Epic**: Downhill Blade Jam MVP
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 3`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief (MVP feature 3, Player goal & fail state), scoped to this story:*

- [ ] Landing angle and impact speed decide whether a landing is a crash
- [ ] A hard hit on an obstacle is a crash
- [ ] Falling off the course or into a hazard is a crash
- [ ] The cause of each crash is readable to the player
- [ ] In checkpoint mode a crash returns the skater to the last checkpoint with the timer still running

---

## Implementation Notes

Basic crash checks exist in `src/player/skater.gd` from the prototype.

---

## Out of Scope

- Story 005: hardcore mode and restart flow

---

## Files

- `src/player/skater.gd`
- `src/player/skate_math.gd`
- `tests/unit/skater/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/skater/story-003-crash-rules_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/downhill-blade-jam/story-001-skater-controller.md`
- Unlocks: None
