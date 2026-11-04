# Copperline Mountain: unmarked, emergent lines with crossovers (2026-11-04)

Conner: "we should not be marking lines, they should be emergent for the player to discover, and they should have lots of options to cross over and test different paths". Design: `design/levels/copperline-mountain.md` §3.2 and §4.

Run result: launched (Linux, OpenGL compatibility renderer under llvmpipe, 1600x900) and observed. Colours look washed out under llvmpipe.

- `upper/`: fixed high camera over the upper fan. No strand poles or lip paint; concrete crossover bands join the strands (X1–X3 visible). The T-shaped posts are chairlift towers (scenery).
- `mix_ride/`: the dev autopilot rides a mixed line from (−60, −318): X3 crossover → Teal → Meadow → The Ramp. Splits 0:39.6 / 1:18.1 / 1:36.1, finish 1:50.3, no crash.
- Headless bot re-test of the main lines, same build: Blue 1:26.98, Teal 1:38.66, Rust 2:04.28, no crashes.
- `stamp.txt`: hashes of the files this evidence proves.
- Update (same day, after the skater's grip-fade change): the Rust chute's hairpin into the Ore strand was eased (design §4). Headless re-test: Blue 1:28.98, Teal 1:37.13, Rust 1:59.69, mixed line from (−60, −318) 1:49.83, no crashes. Screenshots above predate this change; the eased bend is off-camera.
