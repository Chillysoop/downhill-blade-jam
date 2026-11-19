# Story 002: Grinding on rails and ledges

> **Epic**: Downhill Blade Jam MVP
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 2`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief (MVP feature 2, Controls: Grind), scoped to this story:*

- [ ] Jumping onto a rail or ledge locks the skater on automatically (snap-on)
- [ ] The skater balances along the rail and carries speed through it
- [ ] Jumping again leaves the rail
- [ ] Rails and ledges can be placed on courses from course data

---

## Implementation Notes

None yet.

---

## Out of Scope

- Story 003: crashing off a rail
- Story 004: where rails sit on the course

---

## Files

- `src/player/skater.gd`
- `tests/unit/skater/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/skater/story-002-grinding_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/downhill-blade-jam/story-001-skater-controller.md`
- Unlocks: None
