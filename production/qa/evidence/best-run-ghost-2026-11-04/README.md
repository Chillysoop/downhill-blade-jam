# Evidence: ghost of your best run

Spec: `design/quick-specs/best-run-ghost-2026-11-04.md`. Captured 2026-11-04 under
xvfb + llvmpipe (OpenGL compat): colours are washed out compared with Forward+
on Windows, which makes the pale ghost look fainter than it will in game.
`stamp.txt` hashes the files these shots prove.

| Shot | How | Shows |
|---|---|---|
| (setup) | `-- --course=test_slope --autopilot=0.3` | FINISH 0:19.42; `user://ghosts/test_slope.ghost` written although a 0:19.42 best already existed from before ghosts (no-ghost-yet rule) |
| `01-ghost-on-test-slope/` | `-- --course=test_slope --autopilot=3.5 --hops=1.5 --shots=0.5,4,9,14` | Ghost waits/starts with the clock, then rides its own lane ahead; slower run did not overwrite the ghost (same md5 before/after) |
| (setup) | `-- --route=blue` on Copperline | FINISH 1:26.98, `copperline_mountain.ghost` written (125 KB) |
| `02-ghost-on-copperline/` | `-- --route=teal --shots=3,12,25` | 3 s: the ghost mid-stride on the blue line beside the teal run (same figure as the skater, skate pushed out); by 12 s the lines have split and it is out of view |

Unit tests: `tests/unit/ui/test_ghost_track.gd` (sampling, interpolation,
teleport snap, save-format round trip and rejection), PASS.

Run result: PASS. Not covered: watching a whole ghost run frame by frame, and the
fade at the ghost's finish (covered by logic only).
