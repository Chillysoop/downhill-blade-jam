# Story 001: Skater controller

> **Epic**: Downhill Blade Jam MVP
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-04

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 1`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the brief (MVP feature 1, Controls), scoped to this story:*

- [ ] Steer (A/D, left stick) turns the skater; sharper turns scrub a little speed
- [ ] Tuck (W, trigger) gives more speed and less steering
- [ ] Brake (S, trigger) slows the skater down
- [ ] Jump: hold to crouch, release to pop; a longer hold pops higher, a quick tap is a small hop
- [ ] Releasing jump just before landing pops again on touchdown, so hops chain
- [ ] Air steering rotates the skater to line up the landing; no trick buttons
- [ ] Momentum and gravity drive speed: no speed is created from steering

---

## Implementation Notes

Much of this exists from the movement prototype and the realism pass (`src/player/`). This story records it and closes the gaps.

---

## Out of Scope

- Story 002: grinding
- Story 003: crash rules

---

## Files

- `src/player/skater.gd`
- `src/player/skate_math.gd`
- `src/player/skater_tuning.gd`
- `assets/data/skater_tuning.tres`
- `tests/unit/skater/`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*At `qa.level: minimal` tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/skater/story-001-skater-controller_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/downhill-blade-jam/story-002-grinding.md`, `production/epics/downhill-blade-jam/story-003-crash-rules.md`
