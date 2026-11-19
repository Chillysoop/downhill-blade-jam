# Evidence: air spin from takeoff + pumping (2026-11-19)

Spec: design/quick-specs/air-spin-and-pumping-2026-11-19.md

- shot_03.53.png: test slope, the skater mid-hop (shadow offset), straight line, no spin from a tap.
- Bot routes (telemetry logs here): Hillcrest house 1:30.89 (was 1:36.19), runway 1:13.12; Copperline blue 1:28.18, teal 1:38.23, rust 2:11.52; test slope 0:19.16; hop chain every 1 s on the test slope finishes 0:31.61. Highest speed on any route 99 km/h (Copperline).
- Hillcrest "open" bot hits an obstacle at t=9.58 s. It does the same on the code before this change (hc_open_before_change.log), so it is the bot's route, not this change.
- Unit: tests/unit/skater/test_skate_math.gd PASS. test_slow_sideways_landing_steps_around watched failing before the fix.
