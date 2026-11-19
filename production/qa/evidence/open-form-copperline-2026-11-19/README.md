# Copperline Mountain v2 "Open Form": run-and-observe evidence (2026-11-19)

Conner: "i can just hold forward and finish. that is antithetical to the game. Lots of obstacles, lots of turning, lots of finding good lines", "make the levels way more fluid and open form", "think mx vs atv big open world maps, but more limited and downhill for us", "the entire map can ebb left and right, so you can't just bomb straight down". Design: `design/levels/copperline-mountain.md` §5.

Run result: launched (Linux, OpenGL compatibility renderer under llvmpipe, 1600x900) and observed. Colours look washed out under llvmpipe; Windows renders darker and more saturated, so slopes and landforms read more clearly there.

- `top_down_map.png`: hillshaded top-down map from the course data (1 px = 2 m). Pale = concrete, green = scrub, brown = scree, dark = rock (the dots are rock tors; trees and boulders are not drawn). Bot lines planned through the obstacle field: blue = west, magenta = centre, orange = east. Red = straight down. Green dotted lines = splits and finish.
- `overview_upper/`: fixed high camera over the upper valley, showing the obstacle field (tree clumps, boulders, rock tors) with gaps to pick through, soft-edged rough patches, and no markers.
- `ride/`: the dev autopilot on the centre line.
- Bot results (headless, same build, skating physics 1dc2ac4): planned lines west 4:03, centre 3:30, east 3:24, no crashes. Hold forward from the start crashes at z ≈ −164 after 13 s, every attempt. Straight down: stopped against the east bank at z −325.
- `stamp.txt`: hashes of the files this evidence proves.
