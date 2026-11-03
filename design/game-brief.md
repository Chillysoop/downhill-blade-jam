# Game Brief: Downhill Blade Jam (working title)

**One-sentence pitch:** Bomb an open mountainside on inline skates, carving, pumping, grinding and gapping your way to the bottom, where the fastest line is a secret the mountain makes you earn.

## Core loop
- Drop in at the top and pick a line down an open slope that keeps branching.
- Go fast by skating, grinding, jumping and tucking.
- Crash or finish, see your time and splits against your best, and restart instantly.
- Every run teaches you a faster line, a tighter turn or a skip you hadn't spotted, so you go again.

## Player goal & fail state — what "working" looks like
- **Goal:** reach the finish gate as fast as possible. A run is complete when you cross the finish, and a good run beats your personal best or your ghost.
- **Fail state:** a bad landing, a hard hit on an obstacle, falling off the course or into a hazard is a crash. A crash sends you to the last checkpoint with the timer still running (checkpoint mode), or ends the run (hardcore mode). Restart from the top is always one button away.

## MVP — what must exist to be the game
1. A skater controller driven by physics, with simple, intuitive controls: steer, tuck, brake and jump. Momentum and gravity do the rest.
2. Grinding on rails and ledges, with snap-on, balance and speed carried through.
3. Crash rules that are readable and fair: landing angle, impact speed and collisions decide whether you bail.
4. One open course with a main line, several alternate routes and at least three big skips.
5. A run timer, splits at checkpoints, a personal-best ghost, and instant restart.
6. A chase camera that keeps up at high speed and lets you read the slope ahead.

## Controls — simple and intuitive
- **Steer:** left stick / A-D. Turning sharper scrubs a little speed.
- **Tuck:** hold a trigger / W for more speed and less steering.
- **Brake:** hold a trigger / S to slow down.
- **Jump:** hold to crouch, release to pop. A longer hold gives a bigger pop.
- **Grind:** jump onto a rail or ledge and you lock on automatically. Jump again to leave it.
- **Air:** steer to rotate and line up the landing. No trick buttons.
- **Restart:** one button, any time.

## Out of scope — not building this
- No multiplayer, online leaderboards or level editor (for now).
- No trick-scoring system: tricks matter only when they make you faster.
- No story, characters or unlockables in the MVP.
- No procedural generation: courses are hand-built so routes can be learned.
- One course only until the movement feels great.

## Build order
1. **Movement prototype** (the risky part): the skater on a greybox test slope with steering, tuck, brake, jumps, landings and crashes. Tune until it's fun to just roll down a hill.
2. **Grinding**: rails and ledges added to the test slope.
3. **First full run**: one greybox course with a main line, branches, three skips, a timer, splits and instant restart.
4. **Speedrun layer**: personal-best ghost, split comparison, checkpoint and hardcore modes.
5. **Look and sound pass**: art style, skate audio and particles applied to the course.

---
**Who it's for / what they feel:** speedrunners and time-attack players who want the flow of a perfect line and the rush of finding a skip that cuts 10 seconds.

**Art & audio direction:** clean, readable low-poly mountain in the vein of Lonely Mountains, with strong colour cues for routes and hazards; wheel roar, wind rising with speed, and punchy landings.

**Reference games:** Lonely Mountains: Downhill (open slope with hidden shortcuts, fair crashes, instant restart) crossed with Skate (weighty, momentum-based board feel) and Tony Hawk's Downhill Jam (inline skating, grinding at downhill speed). Descenders and Lonely Mountains: Snow Riders for the sense of speed and the camera.
