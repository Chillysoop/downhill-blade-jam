# Evidence: Hillcrest Drop open-form pass (2026-11-19)

Godot 4.7.2, opengl3 under xvfb/llvmpipe (washed-out colours vs Forward+ on Windows).
Design: `design/levels/hillcrest-drop.md` §10b.

| Folder | Shows | Result |
|---|---|---|
| overview_open_blocks | From above Crest Way: open blocks next to built blocks, plaza bowl and fountain | Open blocks read as paved, rolling space between the streets |
| ride_open_block | Test bot carving across an open park block from Juniper | Rolls off the street with no curb, over a mound, at 12-45 km/h |

Headless segment runs (route `open`, 14 s each from seven intersections down Juniper): no crashes; two stalls where the bot steered into a parked bay (bot does not dodge).
