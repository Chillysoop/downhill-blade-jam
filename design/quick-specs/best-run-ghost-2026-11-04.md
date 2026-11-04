# Quick Spec: Ghost of your best run

**Category:** Small addition (speedrun layer, game brief MVP item 5 / build order 4)
**Date:** 2026-11-04
**Requested by:** Conner: "a ghost of your fastest run would be cool to have permanently"
**Design record:** `design/game-brief.md` (Core loop and MVP 5: "a personal-best ghost")
**Builds on:** `design/quick-specs/run-menus-2026-11-04.md` (saved bests per course id)

## Change

1. Every run is recorded while the clock runs: the skater's position, body
   orientation and crouch, sampled at a fixed rate.
2. When a run is faster than the course's saved ghost (or the course has no
   ghost yet, including a best time set before ghosts existed), its recording is saved on the
   player's PC as that course's ghost (`user://ghosts/<course id>.ghost`),
   replacing the old one. It survives restarts, map switches and closing the
   game, the same as the best time.
3. On every run of that course the ghost rides along: a see-through blue copy of
   the skater that starts when your clock starts and moves exactly as your best
   run did. It waits at the start with you, and fades out once it crosses the
   finish. The pause menu freezes it with the clock.
4. The ghost has no collision and never affects the player.
5. Crash respawns in the recorded run show as the ghost jumping to the
   checkpoint (no smear between far-apart samples).

## Tuning knobs (`assets/data/ghost.json`)

- `enabled` (true), `sample_hz` (20), `color` (RGBA, light blue, alpha 0.45),
  `teleport_m` (8: samples further apart than this snap instead of blending),
  `fade_s` (0.6: fade-out after the ghost finishes).

## Acceptance criteria

- [ ] After a first finish on a course, the next run shows a ghost at the start.
- [ ] The ghost follows the best run's line and timing (same finish time).
- [ ] A slower finish does not replace the ghost; a faster one does.
- [ ] The ghost is still there after quitting and relaunching.
- [ ] Unit tests cover sampling, interpolation, teleport snapping and the
      save format round trip.

## Out of scope

Ghost on/off setting in a menu, live time gap to the ghost, downloadable or
developer ghosts, several ghosts at once.
