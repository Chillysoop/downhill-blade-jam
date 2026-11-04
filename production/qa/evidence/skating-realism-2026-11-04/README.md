# Skating realism pass, 2026-11-04

Implements design/game-brief.md "Controls" (steer, push/tuck, brake, jump) with
real inline skating physics. Screenshots from xvfb + opengl3 (colours look
washed out under llvmpipe; not representative of Forward+ on Windows).

| Shot | Shows |
|---|---|
| stride/shot_01.67.png, shot_01.87.png | Striding off the start: pushing skate swept out to the side |
| stride/shot_06.00.png | Tuck at speed |
| carve/shot_04.07.png | Carving right with steer 0.8: body leans into the turn |
| slide/shot_09.33.png, stride/shot_09.60.png | Powerslide braking from ~55 km/h |

Run result: test slope finished by autopilot lane 0.3 in 19.4 s (was 14.5 s),
top speed 91 km/h (was 109 km/h). Powerslide from 57 km/h to 10 km/h in ~3.5 s.
Unit tests: `godot --headless --script res://tests/unit/skater/test_skate_math.gd` PASS.
| tstop/shot_02.07.png | T-stop at low speed (2026-11-04, replaces the heel brake visual at Conner's request) |
