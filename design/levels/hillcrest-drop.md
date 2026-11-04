# Hillcrest Drop: Level Design

> **Status:** IN REVIEW with Conner (greybox v1 built 2026-11-04). Written by the level-designer role inside `/team-level hillcrest-drop` (team.size: individual, so art, systems and QA notes are folded in here).
> **Design record:** `design/game-brief.md` (rigor: minimal, no GDDs). Course roster entry: `design/levels/copperline-mountain.md` §0.1 ("Hillcrest Drop: the steep city").
> **Conner's asks, verbatim:**
> - *"the game feels too much like skiing right now. I think we need a first level that's maybe more urban, like set in a fictional version of san francisco where you go from top of the hill, down through crowded streets, and finish by crossing a line and jumping into the bay"*
> - *"make interesting features like downhill street with a flat level cross street at the bottom that you can jump off and over a house, landing cleanly on another downhill street as a shortcut, stuff like that"*
> - *"steep grid but no dead ends, but challenging sections that incentivize you to find the best lines / skips / shortcuts"*
> - *"we should not be marking lines, they should be emergent for the player to discover, and they should have lots of options to cross over and test different paths"*
> **Decisions (Conner):** concept "Steep grid" chosen; no dead ends; no route paint or markers anywhere (supersedes Copperline's "skips hinted with paint" default for this course).
> **Physics basis** (`assets/data/skater_tuning.tres`, real-skate pass): g 9.81; tucked drag 0.00225/m; T-stop 3.4 m/s², hard T-stop 6 m/s² above 6 m/s; charged pop ≈1.2 m; landing crash above 11 m/s into the surface or 60°; wall/obstacle crash above 9 m/s into it.
> **Conventions:** metres; start near the origin; downhill = −Z; +X = right looking downhill; Y up.
> **Source of truth for numbers:** `tools/levels/gen_hillcrest.py` (every table below is a named constant there) → `assets/data/course_hillcrest_drop.json`.

---

## 1. Concepts considered

| Concept | Summary | Outcome |
|---|---|---|
| **A. Steep grid** | Five steep downhill streets crossed by nine flat cross streets; every intersection is a launch; alleys and lanes cut across blocks | **CHOSEN**, with Conner's change: no dead ends |
| B. One big avenue | A wide central avenue with side streets that split and rejoin | Rejected: fewer route choices |
| C. Switchback hill | Zigzag streets with stairway cuts | Rejected: slow, technical, reads like a hiking trail |

## 2. Identity

- **Place:** a fictional bay city on a steep hill. All street names are invented. Painted row houses step down every block, a downtown of taller towers rises at the bottom left, a red radio mast marks the summit, and a red suspension bridge, a rock island and far hills sit across the bay.
- **Signature:** *the flat intersection is the kicker.* Each cross street is level, and where a steep block starts below it the crown of the road throws you into the air. Hit it fast and you fly half a block.
- **Feel:** precision at speed in a tight, crowded space. Concrete and asphalt everywhere; walls, parked cars, people and traffic are what bite.
- **Not skiing:** no open slope. Space is made of streets, curbs, buildings and gaps, and speed is controlled by line choice, braking and where you take off.

## 3. Layout

### 3.1 Grid

- **Downhill streets** (X): Quarry St −250, Vesper St −125, Hillcrest Ave 0, Juniper St 125, Tidewater St 250.
- **Cross streets** (Z): Crest Way −40, Alta St −150, Sacra St −260, Pine Terrace −370, Larch St −480, Fogline St −590, Wharf Hill St −700, Lower Court −810, Shore St −920; then the **Bayfront** promenade at −1000 (26 m wide) and the **seawall** at −1013.
- Streets are 12 m curb to curb with 3.5 m raised sidewalks (0.15 m curbs); building line 9.5 m from the centre line.
- **Start:** Summit Park plaza (0, 26, y 9). The drop-in runs down Hillcrest Ave to Crest Way at about 18%.
- **Finish:** cross the line at the end of the Finish Pier (0, −1102.5) as you leave its lip, and fly into the bay. Splash ends the run.
- Total drop ≈ 121 m over ≈ 1.13 km.

### 3.2 Intersection heights (y) and block grades

| Cross street | Quarry | Vesper | Hillcrest | Juniper | Tidewater |
|---|---|---|---|---|---|
| Crest Way | −6 | −3 | 0 | −3 | −6 |
| Alta | −17 | −18 | −15 | −14 | −15 |
| Sacra | −30 | −42 | −33 | −28 | −26 |
| Pine Terrace | −44 | −50 | −50 | −42 | −38 |
| Larch | −58 | −64 | −70 | −56 | −50 |
| Fogline | −72 | −80 | −84 | −70 | −66 |
| Wharf Hill | −86 | −93 | −96 | −90 | −80 |
| Lower Court | −97 | −103 | −104 | −98 | −92 |
| Shore | −105 | −109 | −109 | −104 | −100 |
| Bayfront | −112 | −112 | −112 | −112 | −112 |

Block grades (%, top to bottom), measured curb line to curb line:

| Street | grades |
|---|---|
| Quarry | 12, 14, 15, 15, 15, 15, 12, 9, 11 |
| Vesper | 16, **26 (The Wall)**, 9, 15, 18, 14, 11, 7, 5 |
| Hillcrest | 16, 20, 19, 22 (lower Hillcrest, 30% at the top), 15, steps, 9, 5, 5 |
| Juniper (cable car) | 12, 15, 15, 15, 15, **22**, 9, 7, 13 |
| Tidewater | 10, 12, 13, 13, 18, 15, 13, 9, 20 |

Cross streets are level inside each intersection and slope straight between intersections, so several of them run downhill sideways (Larch drops 14 m from Tidewater to Hillcrest). That makes the cross streets real lines, not just connectors.

### 3.3 Intersection crowns (the launch rule)

Every downhill exit from an intersection has a crown lip: the road rises **0.35 m over 5 m** before the block drops away. Seven intersections have a **big crown, 0.75 m over 6 m** (Crest/Hillcrest, Alta/Vesper above The Wall, Alta/Hillcrest, Sacra/Tidewater, Larch/Juniper into Fog Alley's street, Fogline/Quarry, Wharf Hill/Vesper).

Air off a crown at speed *v*, lip angle *α*, block grade *θ*: flight time t = 2·v·(sin α + cos α·tan θ)/g (approx.), so at 20 m/s off a normal crown onto a 20% block you fly ≈ 22 m, and ≈ 35 m off a big crown. Landing impact into the slope is ≈ v·sin α + g·t·cos θ − v·sin θ, which stays under the 11 m/s crash limit up to about 30 m/s on normal crowns. Big crowns at full tuck can overshoot the steep part and land on the eased-out foot of the block: that is the risk that makes them a choice.

### 3.4 No dead ends

Every street runs through. Where a section is hard there is always a slower way through it:

| Hard section | Fast way | Slow way |
|---|---|---|
| Pine Terrace / Hillcrest (house) | The House Jump | Terrace Ramp: a steep switchback off the terrace, right of the house, onto lower Hillcrest |
| Hillcrest Steps (Fogline → Wharf Hill) | Gap the flights at speed (11 flights of 6 steps, 1.08 m each, 5.4 m landings) | The smooth runway beside the stairs (right side, 4.5 m wide): no gapping needed. Rolling the stairs themselves is slow and bumpy |
| The Wall (Vesper, Alta → Sacra, 26%) | Tuck it off the big crown | Brake down it, or cross on Lantern Alley |
| Juniper (cable car) | Thread past the oncoming cable car | Any other street |

## 4. Lines, skips and crossovers (emergent, nothing painted)

Nothing marks a line: no yellow paint, no arrows, no route poles. Only normal road paint exists (centre lines, crosswalks, cable car tracks). Takeoffs look like what they are: a crowned road, a driveway ramp, a stair edge, the pier's end.

### 4.1 The House Jump (signature skip)

- Hillcrest Ave comes down Sacra → Pine Terrace at 19% into the level terrace (y −50).
- Straight ahead across the terrace is a **driveway ramp** (plain concrete, 5 m wide, 0.8 m over 4 m) into a house that sits below the terrace: its roof is at y −51, 1 m under the road.
- Behind the house, **lower Hillcrest** starts at y −56 (z −399) and drops at 30% for 46 m, then eases into Larch.
- Fly the house and land on the 30% slope. Window (simple ballistics, confirmed roughly by the test bot): fast enough and you clear the roof onto the steep street; **come up short and you land on the flat roof** (the bot at 51 km/h touched down on it), roll off its back edge and drop 5 m onto lower Hillcrest, slower but alive (the "near-miss goes somewhere" rule). Too slow (under ≈ 35 km/h) and you hit the house front. Far too fast (≈ 80 km/h+) you land past the steep part and bail. The best result depends on how you came down Sacra, so the corner above matters.
- Slow way: turn right on the terrace and take the Terrace Ramp (two tight bends, ~25-29%) onto lower Hillcrest.

### 4.2 Crossovers (where lines swap)

- **Every cross street** (9 of them, all full width) is a place to change streets. Turning onto one at speed is the cost: turn radius r = v²/(g·tan lean), so at 20 m/s you need ≈ 41 m of road to turn 90°, at 11 m/s ≈ 12 m. Carrying speed across means using the cross streets' own sideways grades and drifting the corner wide.
- **Diagonal alleys** (6 m wide, between buildings, intersection to intersection), the fast way to swap streets without a 90° turn:
  - Lantern Alley: Alta/Vesper → Sacra/Hillcrest (around The Wall, sets up the House Jump).
  - Mint Alley: Alta/Tidewater → Sacra/Juniper.
  - Rope Alley: Pine Terrace/Quarry → Larch/Vesper.
  - Fog Alley: Larch/Juniper → Fogline/Hillcrest (17%, narrow and fast, straight into the Steps).
  - Cannery Cut: Wharf Hill/Hillcrest → Lower Court/Vesper.
  - Tar Alley: Lower Court/Tidewater → Shore/Juniper.
- **Mid-block lanes** (4.5-5 m, straight down between buildings, entering the cross streets mid-block through a gap in the sidewalk): Bakers Lane (x −187, Alta → Sacra), Pinch Lane (x −62, Larch → Fogline), Sailors Lane (x 187, Wharf Hill → Lower Court), Kite Lane (x 62, Lower Court → Shore).
- **Sidewalks** are raised 0.15 m: hop up onto them to dodge parked cars or traffic, and hop off them to pop. Hitting a curb side-on at speed is an obstacle hit.

### 4.3 Intended line families (to be confirmed by playtest timing)

1. **Hillcrest bomb + House Jump:** drop-in → Hillcrest → speed-check → House Jump → lower Hillcrest → Larch → Hillcrest → gap the Steps → Hillcrest to the Bayfront → pier.
2. **The Wall:** Crest Way left → Vesper → big crown at Alta → The Wall → Rope Alley or Vesper down.
3. **Cable car street:** Juniper all the way, threading the oncoming cable cars; Fog Alley crossover to the Steps.
4. **Edges:** Quarry or Tidewater: gentler, fewer people, longer cross-street run to the pier.

The fastest line should be a mix: no single street wins every block.

## 5. Hazards ("encounters")

- **Parked cars** both curbs of most blocks (gaps at random), solid; hitting one above 9 m/s is a bail. They narrow the 12 m road to about 8 m.
- **Cross traffic** on Alta, Larch, Wharf Hill and Shore: two cars each way per street at 8-9.5 m/s, looping. Being touched by a moving car is a bail. Traffic runs on the run clock, so every restart replays it identically: a speedrunner can learn the timing.
- **Cable cars** on Juniper: three, climbing at 4.2 m/s up the centre tracks, oncoming. Touch = bail.
- **Bayfront traffic**: three cars each way at 6.5-7 m/s across the promenade you must cross to reach the pier.
- **People**: small groups on most corners, strollers on the sidewalks, people walking the crosswalks on about half the intersections (never on the House Jump or the Steps), big tourist crowds on the Bayfront and fans lining the pier. Hitting anyone above 3 m/s is a bail.
- **Buildings** line every block: a wall hit above 9 m/s is a bail.
- **The bay**: falling in anywhere before the finish line is a bail; after it, the run ends with a splash.

## 6. Checkpoints and splits

- Split 1 **Pine Terrace** (z −370), Split 2 **Wharf Hill** (z −700), **Finish** at the pier end (z −1102.5).
- A crash respawns you on the intersection of the street nearest where you crossed the last split, facing straight downhill, clock running.

## 7. Pacing (intensity 1-5)

| Section | Intensity | Note |
|---|---|---|
| Summit drop-in | 3 | 18% straight out of the gate into Crest Way's crown |
| Alta-Sacra | 4 | The Wall, first cross traffic |
| Pine Terrace | 5 | House Jump decision |
| Larch-Fogline | 4 | Fog Alley, Pinch Lane, steep cross streets |
| Steps | 5 | Gap or roll |
| Wharf Hill-Shore | 3 | gentler grades, downtown towers, traffic |
| Bayfront + pier | 4 | cross the traffic, thread the crowd, launch |

Target time: unknown until playtested. Estimate from average speed 16-20 m/s over ≈1.2 km of line: **≈60-75 s** for a strong run.

## 8. Look and landmarks

- Asphalt streets (dark grey, `look.terrain` in the course data), pale sidewalks, yellow centre lines, white crosswalks, steel cable car tracks.
- Pastel row houses (7.5-13.5 m tall) stepping down the hill; grey downtown towers (18-46 m) on the lower-left blocks; courtyards are grass (slow, and walled in).
- Landmarks: red radio mast at the summit; ferry-hall clock tower on the Bayfront left of the pier; red suspension bridge across the bay to the right; rock island to the left; far hills.

## 9. Systems notes (built for this course)

- City kit (`src/levels/course/city_kit.gd`): merged buildings and props ("solids"), crowds, traffic, road paint. Streets are stamped into the ground grid from [x, z, y] polylines; lots between streets use the intersection height grid.
- Course clock (`CourseBuilder.clock`) drives traffic and walkers; it resets on restart and pauses while you wait at the start.
- Water (`water` block): splash after the finish ends the run; before it, a bail.
- Skater gained a public `bail(reason)` so course hazards can crash it; no skating physics changed.

## 10. QA

- **Acceptance:** the course loads from the map select and as the default; the drop-in starts on input; every street block, alley and lane is rideable top to bottom without a forced stop; the House Jump is clearable and the Terrace Ramp gets a slow rider past it; the Steps are rideable both slow and fast; crossing the pier line then splashing shows the time; falling in the bay before the line respawns you.
- **Edge cases:** respawn pads are on intersection centres so no pad is inside a building; walkers never cross the House Jump or Steps entries; the cable car and cross traffic loops are on the run clock (identical every restart).
- **Evidence:** `production/qa/evidence/hillcrest-drop-2026-11-04/`.

## 11. Playtest notes (test bot, greybox v1)

- Drop-in to Crest Way from standing: ≈ 47 km/h at the crown; first crown air 0.7 s.
- Hillcrest bomb reaches ≈ 74 km/h by Sacra; crown air ≈ 1 s.
- House Jump at 51 km/h: lands on the roof, rolls off onto lower Hillcrest (near-miss path works).
- Steps runway: 22 km/h in, ≈ 49 km/h out. Rolling the stairs at 40 km/h cap: very slow (it is meant to be gapped).
- Bayfront to the pier end at 30 km/h in: the finish line and splash trigger correctly.
- The bot cannot dodge people, parked cars or traffic, so it does not post full-run times; target time stays an estimate until Conner plays it.

## 12. Inspiration notes (Conner shared outside feedback, 2026-11-04)

Taken as inspiration, not a spec. Already reflected: one obvious road first (Hillcrest), skips whose payoff depends on entry speed (House Jump), near-misses that land on a slower route (the roof), crossovers everywhere (alleys, lanes, cross streets), memorable landmarks (summit mast, ferry tower, bridge). Candidates for v2: a parking garage whose roof links two streets, a "how do I get up there" rail or ledge line visible from below, a practice marker that restores speed (run-menus owner), sightline pass at full speed.

## 13. Open questions for Conner

- Is the House Jump window right (too strict / too loose)?
- More or fewer people and cars?
- Should traffic stop for you at crosswalks or ignore you (current: ignores you)?
