# Story 004: Open course with routes and skips

> **Epic**: Downhill Blade Jam MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 4`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief (MVP feature 4), scoped to this story:*

- [ ] One open course with a main line from start to finish gate
- [ ] Several alternate routes that branch from and rejoin the main line
- [ ] At least three big skips
- [ ] Step-up sequences (chained hops up ledges and stairs) that lead to shortcuts or big gaps
- [ ] The course is hand-built (no procedural generation) so routes can be learned

---

## Implementation Notes

Copperline Mountain greybox exists (`assets/data/course_copperline_mountain.json`, `src/levels/course/`, `design/levels/copperline-mountain.md`).

---

## Out of Scope

- Story 002: rails and ledges as grind objects
- Story 005: timer and splits

---

## Files

- `assets/data/course_copperline_mountain.json`
- `src/levels/course/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/course/story-004-open-course_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/downhill-blade-jam/story-001-skater-controller.md`
- Unlocks: `production/epics/downhill-blade-jam/story-005-run-timer-and-ghost.md`
