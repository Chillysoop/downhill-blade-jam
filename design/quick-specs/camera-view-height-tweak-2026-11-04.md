# Quick Design Spec: Higher chase camera that reads the slope ahead

**Type**: Tweak
**System**: Chase camera (`src/camera/chase_camera.gd`)
**GDD Reference**: No GDD for the camera (workflow: minimal). Using `design/game-brief.md`, MVP item 6: "A chase camera that keeps up at high speed and lets you read the slope ahead."
**Date**: 2026-11-04

## Change Summary

Raise and pull back the chase camera, aim it further down the course, and tilt it with the slope so the ground ahead stays in view on steep sections. Move the camera's numbers into a tuning file.

## Motivation

Conner (playtest, 2026-11-04): "our view angle needs to be higher so we can more easily see obstacles / pathing ahead of the character." The current camera sits 2.4 m up and aims only 6 m ahead at chest height, so on a downhill slope it looks out level while the ground falls away. Obstacles and route choices appear late, which works against a speedrun game where lines are picked early.

## Design Delta

Current behaviour (from `chase_camera.gd`): the camera follows 5.5 m behind and 2.4 m above the skater and aims at a point 6 m ahead and 0.8 m above the skater.

This spec changes that to:

1. The camera follows `distance` behind and `height` above the skater, along the smoothed direction of travel (unchanged logic, new values).
2. The camera aims at a point `look_ahead` metres ahead of the skater, `aim_height` above the skater's height, **plus the drop of the slope over that distance**.
3. The slope is the skater's ground grade along the camera direction, worked out from the ground normal while grounded, smoothed with `slope_sharpness`, and held at its last value while airborne or crashed (so jumps don't swing the camera).
4. The camera also rises by the same grade over `distance`, so it keeps its clearance above the uphill ground behind the skater.
5. `slope_follow` scales both slope terms (0 = old flat behaviour, 1 = full).
6. **Terrain clearance:** each frame the camera casts a ray from the skater (1 m up) to its desired position. If terrain or a wall is in the way, the camera moves in to `clearance` metres short of the hit, so it never sits inside a valley wall or channel side. It eases back out with `follow_sharpness` once the view is clear.
7. FOV widening with speed is unchanged.

## New Rules / Values

| Parameter | Old | New | Rationale |
|---|---|---|---|
| height | 2.4 m | 4.8 m | Higher eye line, more of the course visible over obstacles |
| distance | 5.5 m | 7.5 m | Keeps the skater a readable size with the higher eye |
| look_ahead | 6 m | 16 m | Aim at where you will be in about a second at speed |
| aim height | 0.8 m (hardcoded) | 0.0 m (`aim_height`) | Aim at the course, not the sky |
| slope_follow | n/a | 1.0 (range 0 to 1.5) | Tilt with the slope |
| slope_sharpness | n/a | 3.0 /s (range 1 to 8) | Smooth slope changes, no jitter on bumps |
| grade clamp | n/a | -1.5 to 0.5 | Stops wild aim on walls or near-vertical faces |
| clearance | n/a | 0.4 m | Gap kept between the camera and terrain it is pulled in by |

All camera values move to a new `CameraTuning` resource at `assets/data/camera_tuning.tres` (same pattern as `skater_tuning.tres`), per the coding standard that gameplay values are data-driven.

## Affected Systems

| System | Impact | Action Required |
|---|---|---|
| Chase camera | New aim and position rules, values moved to data | Update `chase_camera.gd`, add `camera_tuning.gd` + `.tres` |
| Main scene wiring | Camera needs its tuning resource | Assign the resource in `src/main.gd` |
| Course (Copperline Mountain) | Camera ray hits its terrain collision | No action |
| Skater | Read only (`ground_normal`, `state`) | No action |

## Acceptance Criteria

- [ ] Camera values are read from `assets/data/camera_tuning.tres`
- [ ] On the test slope at speed, the horizon sits above the middle of the screen and the finish area is visible from the last section (prototype comparison shots shared with Conner, 2026-11-04)
- [ ] The camera does not tilt up or swing during a jump
- [ ] On Copperline Mountain the camera never ends up inside a valley wall, channel side or cliff band (prototype comparison shots shared with Conner, 2026-11-04)
- [ ] Respawn (R) snaps the camera straight to the new position
- [ ] No regression: camera still follows turns smoothly and FOV still widens with speed
- [ ] Screenshot evidence saved in `production/qa/evidence/`

## GDD Update Required?

No (no camera GDD exists at minimal workflow).
