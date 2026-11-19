# Evidence: snappier pushes, sharper carves, uphill ground contact (2026-11-19)

Spec: design/quick-specs/snappy-skating-2026-11-19.md

- shot_01.27.png, shot_02.53.png: test slope, full steer while striding from a standstill. 20 km/h at 2.5 s while carving a ~2 m circle, body leaned 50° into it.
- Bot routes, before -> after (logs new_*.log, before_*.log):
  - Copperline west 4:03.42 -> 3:21.81, east 3:24.47 -> 3:17.16, centre 3:29.54 -> 3:19.62. Top speeds about the same (66-72 km/h).
  - Copperline "straight" (hold forward) crashes on an obstacle before and after, as the level intends.
  - Hillcrest house, hillcrest, juniper and quarry: the bot hits a pedestrian before and after (the bot can't dodge). It gets there 2-14 s sooner now.
- Test slope 0:19.16 -> 0:17.54. Hop every 1 s: 0:31.61 -> 0:28.05.
- Unit: test_skate_math.gd PASS. 10 new or updated checks watched failing on the old values first.
- Integration: tests/integration/skater/test_skater_ground_contact.gd PASS. Watched failing first: 31 of 60 frames airborne rolling uphill.
