# Evidence: finish screen, pause menu and map select

Spec: `design/quick-specs/run-menus-2026-11-04.md`. Captured 2026-11-04 under
xvfb + llvmpipe (OpenGL compat), so colours are washed out compared with
Forward+ on Windows. `stamp.txt` hashes the files these shots prove.

| Shot | Command (after `--`) | Shows |
|---|---|---|
| `01-first-finish/` | `--course=test_slope --autopilot=0.3 --shots=23` (records cleared) | Results panel 1.2 s after the finish: NEW BEST, 0:19.42, first-finish line, three buttons, Ride again focused |
| `02-second-finish/` | same, run again | Saved best loaded on a fresh launch; same time reads FINISH with "Previous best 0:19.42 (+0.00)" in red |
| `03-pause/` | `--route=blue --menu=pause --menu-at=6 --shots=7` | Pause menu on Copperline; clock frozen at 0:05.9x one second after pausing |
| `04-map-select/` | `--menu=maps --menu-at=3 --shots=4` | Both courses with saved bests; current map marked and focused; blurb shown |
| `05-after-picking-test-slope/` | `--pick-map=test_slope --menu-at=2 --shots=3` | Picking a map reloads into Test Slope at 0:00.00 with its saved best |

Unit tests: `tests/unit/ui/test_run_menus.gd` (records, catalog, delta format), PASS.

Run result: PASS (all five shots match the acceptance criteria). Not covered by
automation: mouse clicks and gamepad navigation (built-in ui_* actions), Quit.
