# Evidence: Story 006 — Chase camera that reads the slope ahead

**Story**: `production/epics/downhill-blade-jam/story-006-chase-camera.md`
**Spec**: `design/quick-specs/camera-view-height-tweak-2026-11-04.md`
**Date**: 2026-11-19
**Build**: Godot 4.7.2, headless Linux, opengl3 under llvmpipe (colours look washed out; judge framing, not colour)

## Run and observe

- `copperline/`: Copperline Mountain, dev autopilot on the Blue line (`-- --course=res://assets/data/course_copperline_mountain.json --route=blue`), shots at 10, 25, 40, 55, 70 s.
- `hillcrest/`: Hillcrest Drop, dev autopilot on the house route (`-- --course=res://assets/data/course_hillcrest_drop.json --route=house`), shots at 8, 16, 24, 32, 40 s.
- `stamp.txt`: content hashes of the files changed by the story.

Run result: OBSERVED — on both courses the camera sits high behind the skater with the horizon in the upper third; on Copperline the slope, grass edges and terrain features well ahead are in view at 49–96 km/h, and on Hillcrest the next intersections, crosswalks and parked cars are visible down the street. No shot shows the camera inside terrain, walls or buildings (Copperline valley sides at 55 s, Hillcrest street walls at 16 s and 40 s).

## Criteria

| Criterion | Result |
|---|---|
| Values read from `assets/data/camera_tuning.tres` | PASS (code: `main.gd` loads it into `ChaseCamera.tuning`) |
| 7.5 m behind, 4.8 m up, aims 16 m ahead | PASS (tuning file values; framing in shots) |
| Aim drops with the slope; horizon above mid-screen | PASS (all shots) |
| Holds tilt in the air, no swing on jumps | DEFERRED to playtest (feel; a still cannot show it). Code only updates the grade while GROUNDED |
| Never inside a wall on Copperline | PASS in the 10 shots taken; full-course coverage DEFERRED to playtest |
| Respawn/restart snaps the camera | PASS by code path (`_on_respawned` calls `snap()`); Hillcrest 24 s shows a bail with the camera in place |
| No regression: turns smooth, FOV widens with speed | DEFERRED to playtest (feel) |

## Sign-off

Lead sign-off: pending Conner's playtest of the build.
