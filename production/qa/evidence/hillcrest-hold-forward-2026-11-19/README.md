# Hillcrest Drop: hold-forward pass (2026-11-19)

Design: `design/levels/hillcrest-drop.md` §10c. Conner: "i can just hold forward and finish. that is antithetical to the game."

| File | What it shows |
|---|---|
| `hold_forward_before_change.txt` | Old course: a bot that only holds forward from the summit finished, `FINISH 1:25.44` |
| `hold_forward_summit.txt` | New course: the same bot hits the building across Crest Way at the first jog, every attempt (people and traffic removed) |
| `sweep.txt` | Hold forward from the top of all 44 downhill blocks, facing straight down, 30 s each, people and traffic removed. `lowest_z` is the furthest it got; `first_crash` is when and why it bailed (`none` means it stopped without bailing) |
| `route_house.txt`, `route_juniper.txt` | A steering bot that brakes to 24 km/h for each jog finishes: House Jump line 2:26.82, Juniper 3:02.63 |
| `holdfwd/`, `overview/` | Screenshots: the hold-forward bot reaching the first jog, and an overhead view of jogged streets and an open-block obstacle field |

Reproduce: `bash tools/levels/hold_forward_sweep.sh <out_dir> 30 3`; routes: `godot --headless -- --route=house --lookahead=10 --no-people --telemetry --quit-after=230`.
Physics: all new-course runs on the merged build up to nw2xqh 7d9be3b (skating fixes incl. air spin and pumping), except `sweep.txt`, which ran on tv2let 1dc2ac4 (same physics). The before-change run was on the 4v4kdh build 1ce68c2.
