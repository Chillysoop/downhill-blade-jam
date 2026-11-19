# Skater physics audit, 2026-11-19

Spec: design/quick-specs/skater-physics-audit-2026-11-19.md

| Shot | Shows |
|---|---|
| shot_04.60.png | Hillcrest Steps at ~20 km/h: airborne off a flight, body upright (was glued along the stair line) |

Bot runs (headless, 2026-11-19), all finish:
- Hillcrest house route 1:36.19 (splits 0:28.38, 0:52.51). Juniper bot hits a pedestrian (bot can't dodge; known).
- Hillcrest x=0 from Fogline: wharf flat holds ~32 km/h striding; before the fix speed rose to 192 km/h on the flat.
- Copperline blue 1:28.12, teal 1:36.98, rust 2:10.53. Test slope 0:19.16.
- Unit suites: SkateMath, CourseMath, GhostTrack, RunMenus PASS. Regression test for the stuck normal watched failing on old code.
