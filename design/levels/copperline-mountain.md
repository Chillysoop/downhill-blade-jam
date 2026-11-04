# Copperline Mountain: Level Design

> **Status:** APPROVED by Conner, 2026-11-04 ("Yes it's ok you should not be able to go straight down. This should be a hard game where you're forced to find creative lines"). Compiled from `production/levels/first-mountain/layout.md`. Originally Written by level-designer inside `/team-level first-mountain` (team.size: individual, so art, systems and QA notes are included here).
> **Design record:** `design/game-brief.md` (rigor: minimal, no GDDs).
> **Conner's ask:** *"the maps should be large, a solid mix of terrain and planted features, it should feel like the player has a ton of variety of choices to accomplish the fastest run"*
> **Follow-up asks from Conner, folded in:** *"make the terrain feel natural"* · surface is *"like a ski slope but with concrete"* · *"plan so that we can have many level designs with unique features … a fun blend of realism but also video game level design."*
> **Decision (Conner):** Concept A "Braided Fan" is CHOSEN. §2 is the full layout built as the Braided Fan, designed directly against A's listed cons (see §2.0).
> **Defaults adopted (Conner didn't object):**
> - Grass and dirt slow you hard; only rock, trees and walls crash you.
> - ~~Obvious skips are hinted with paint marks; three skips are secret.~~ Superseded 2026-11-04, see §3.2: no lines or skips are marked.
> - Target times: ≈65–75 s expert, ≈90–100 s normal.
>
> **Physics basis:** the prototype skater numbers given to this run:
> - g 18 m/s².
> - Terminal speed ≈27 m/s upright / ≈35 m/s tucked on 15°.
> - Push cap 9 m/s; pop 4.5–8 m/s; max hop ≈1.8 m / ≈0.9 s.
> - Crash at >65° landing, >24 m/s normal impact, or >9 m/s wall hit.
>
> Another thread is retuning these, so **every size below is a tuning knob**, and the formulas in §2.11 let a size be recomputed when the numbers change.
> **Conventions:**
> - Units are metres. The start gate is at the origin.
> - Downhill = **−Z**. X = across the slope (−X = west/left looking downhill, +X = east/right). Y = up.
> - All times are **estimates from simplified physics (no drag or rolling-friction model)** and must be confirmed in playtest.

---

## 0. The Bigger Picture

### 0.1 Course Roster
The game will ship with several courses. Each one has a **signature identity**: one kind of space, one standout trick, one colour mood. All courses are our own originals, and none takes its name from another game. Each mixes realism (places that feel like they could exist) with video-game level design (lines, lips and gaps placed on purpose).

- **Copperline Mountain: the open concrete mountain** (this document, full layout in §2).
  - **What it is:** a huge, natural alpine fan poured in smooth concrete like a ski run, a giant skatepark draped over a braided riverbed of a mountainside.
  - **Signature: freedom.** It is wide and open, lines split and rejoin all the way down, crossovers are always possible, and the fastest line is a secret you earn.
  - **Role on the roster:** built specially for this game. It is the most open and flexible course, and it teaches every skill the others test.
- **Hillcrest Drop: the steep city** (inspired by San Francisco; not a replica, all street names invented).
  - **What it is:** a grid of narrow, very steep streets.
  - **Signature trick:** the **flat intersections act as launch tables**. Hit the crest, fly the next block, land on the downslope.
  - **Other features:** sidewalks and curbs as ledges, stair streets and terraced gardens as step-ups, cable-car-style street rails and trolley tracks as grind lines, and parked vehicles and planters as obstacles. **Alleys and stair-lanes are the shortcuts.**
  - **Signature feel: precision at speed.** The space is tight, wall hits punish you hard, and the big skips are the gaps between blocks.
  - **Role on the roster:** narrow and mostly linear, the opposite of Copperline.
- **Spillway Canyon (idea):** a dry concrete flood-control canyon and its dam.
  - **Features:** long transition walls you can carve up, a central low-flow channel as a fast groove, and bridges and pipes as rails.
  - **Signature:** riding walls and banks.
- **Harbour Night (idea):** a night-time descent from a hilltop observatory, through switchback parking structures, down to a lit harbour.
  - **Features:** ramps between parking decks, container stacks as step-ups, and crane rails.
  - **Signature:** verticality, with lighting as wayfinding.

### 0.2 Shared Level Kit
Every course is built from the same kit, so a new course is mostly new *layout and dressing*, not new systems. Sizes come from data and are checked by the same formulas (§2.11).

| Kit piece | What it is | Shared, or course-specific? |
|---|---|---|
| **Ground shape** | Mountain or canyon: a heightfield built from a base profile plus a shape list (§2.4). City: a street spline plus block heights (street = sloped strip, intersection = flat table, sidewalk = curb-height offset). | System shared; shape data per course |
| **Surface types** | Riding surface (concrete or asphalt: fast); rough (grass, dirt, gravel: slow); crash (rock, trunks, walls) | Shared rules; per-course look |
| **Rails** | Steel round or box rail, handrail, fence top, cable-car or trolley rail, pipe, beam. All are one grind component with length, height and profile settings. | Shared component; skins per course |
| **Ledges** | Concrete ledge, curb, retaining wall, rock step, planter | Shared |
| **Kickers / ramps** | Concrete kicker, quarter pipe, bank, hip, rock or dirt roll-in. Parametric: height, lip angle, length. | Shared |
| **Stairs / step-ups** | Parametric rise, tread and count, with optional handrails | Shared |
| **Gaps / drops** | A takeoff lip plus a landing (knuckle and face angle), checked by the gap formula | Shared |
| **Channels / walls** | Concrete channel, canyon slot, alley, pipe/culvert. Parameters: width, wall height, entry flare ≤12°. | Shared |
| **Checkpoints / splits** | Full-width timing plane, respawn pads, gate visuals | Shared logic; gate skin per course |
| **Start / finish** | Start gate, finish line and arch, run-out | Shared |
| **Off-course zones** | Out-of-bounds kill volume and boundary dressing (tree wall, rock wall, building facade, fence) | Logic shared; dressing per course |
| **Colour language** | Colours and shapes for routes, skips, hazards, checkpoints and out-of-bounds (§2.12) | **Shared and fixed in every course**, so players read each new course instantly |
| **Course-specific** | Landmarks; theme set pieces (Copperline's Trestle, Long Groove and Lift Island; Hillcrest's intersection tables and cable rails); ambience and music; the base palette | Per course |

---

## 1. Course Concepts (Copperline Mountain)

All three concepts follow two rules from Conner:
- **The terrain must feel natural:** flowing ridges, gullies, outcrops, tree lines and uneven fall lines, with no straight or grid-aligned shapes in the terrain.
- **The riding surface is smooth concrete poured over a ski-run shape.**

They differ in size, in how routes branch and rejoin, and in the balance between terrain and planted features.

### Concept A: "Braided Fan" (CHOSEN by Conner)
One huge, open alluvial fan about **600 m wide × 1500 m long** that widens as it descends. Lines split and rejoin every 150–250 m, the way channels braid in a riverbed: shallow gullies, low spurs, rock islands and scattered feature clusters, with no hard dividers. About 75% terrain and 25% planted features. As first pitched, skips were mostly natural: a rock overhang lip, two cliff drops, and a long gully you can ride as a pipe. Concrete covers almost the whole fan, so there is little surface contrast to steer route choice.
- **Pros:**
  - The most open and free of the three, so it matches "ski slope" best.
  - Terrain does most of the work, so few assets need to be placed.
  - It's very easy to lay out as a heightfield.
- **Cons:** each one is addressed in §2.0.
  - Weak wayfinding, because nothing separates the routes, so the choices blur together.
  - The straight fall line tends to become "the one obvious line" and kills variety.
  - Skips are hard to make clearly different from each other.
  - There are few places for step-ups and grind lines.
- **Run time:** best ≈65 s, average ≈90 s.

### Concept B: "Three Spines" (rejected; it was the level designer's recommendation)
- **Shape:** a 480 × 1720 m face with an open bowl at the top.
- **Gullies:** two ridges split the middle into three themed gullies (mine, concrete piste, wild scree). Saddles let riders cross between them.
- **Lower half:** a forest and a cliff band, then a village run-out.
- **Mix:** 55/45 terrain to planted features.
- **Strengths:** the most readable choices.
- **Weaknesses:** less open than A, and the most build work of the three.
- **Run time:** best ≈72–76 s, average ≈100–115 s.

### Concept C: "Switchback Town" (rejected)
- **Shape:** a narrow (≈260 m), steep face with about 2.2 km of switchback road through a mine and a village.
- **Mix:** 30/70 terrain to planted features. Every skip cuts across the switchbacks.
- **Strengths:** readable, spectacular skips.
- **Weaknesses:** it feels like a track rather than open, natural terrain, and it overlaps the steep-city course.
- **Run time:** best ≈70 s, average ≈120 s.

---

## 2. Draft Layout: "Copperline Mountain" (Concept A, Braided Fan)

### 2.0 How this layout answers A's cons
| Con | Design answer | Where |
|---|---|---|
| **1. Weak wayfinding** | There are three named **strands**: **Rust** (west), **Blue Crown** (centre), **Teal** (east). Each has its own colour, shape language, feature clusters and a landmark visible from every braid node. Strands are separated only by low rough islands, gravel bars and outcrop clusters, so they are always crossable and never walled off. | §2.5, §2.12 |
| **2. One obvious fall line** | The fan's axis **doglegs**: it drifts west in the upper half, then swings east. The fan's cross-section is **convex** (a raised crown), so the **steepest ground lies in the side strands**, which bend. **The straight start-to-finish line is deliberately one of the slowest and most dangerous.** It crosses a boulder garden, the widest part of the gravel bar, the rough rim above the hidden groove, and a no-go section of the Dry Falls rock band. | §2.4 "Straight-Line Test" |
| **3. Skips too similar** | There are 10 skips across five kinds: **natural** (Long Groove, Needle Drop, Dry Falls Huck, Spur Transfer), **placed step-up + gap** (Pumphouse, Lift Line, Trestle, Chapel), **placed kicker** (Bar Hop), **placed pipe** (Culvert), and **grind** (4 optional rails). | §2.7 |
| **4. No room for step-ups and grinds** | Five **structure islands** sit on rock islands and spurs: Pumphouse, Lift Island, Ore Island (Trestle), Chapel Rock, and the East Spur (bank and hip). Each carries step-ups and/or rails. | §2.4 islands |

### 2.1 Level Name and Theme
**Copperline Mountain** is a vast alpine debris fan spilling out of a high cirque above an old copper-mining valley.
- **The setting:** the fan's natural braided channels, rock islands and gravel bars have been **poured in smooth concrete** along every rideable line. It's a giant skatepark draped over a real mountainside.
- **Built features:** these sit where they would plausibly stand.
  - Mine relics: the Ore Island ruins, the ore trestle, cart rails and a flood culvert.
  - Chairlift: a line down the crown, with a mid-station on Lift Island.
  - An old pumphouse.
  - A chapel on a rock knoll near the toe of the fan.
- **Art style:** clean low-poly with big readable shapes.

**Surface rule:**

| Surface | Where | Effect |
|---|---|---|
| **Concrete** | Strands, crown pistes, fords, decks, all built features | Fast |
| **Rough** (grass, dirt, gravel bars) | Islands, rims, bars | Slow you hard; reduce steering |
| **Crash** (rock outcrops, boulders, trunks, walls, band faces) | Island flanks, boulder fields, cliff faces, trees | Treated as a wall or impact under the crash rules |

**Naturalness rule:**
- No terrain edge is straight or grid-aligned. Strands meander, islands are teardrop-shaped like real braid islands (blunt upstream, tapering downstream), and tree clumps and outcrops are ragged.
- Only man-made things are straight: the trestle, the culvert, stairs, rails and buildings.
- Placed features sit plausibly in the landscape. Kickers are concrete lips built out of banks or rock rolls. Ledges are retaining walls or rock steps. Rails follow paths, fences, walls and old cart tracks.

### 2.2 Estimated Play Time
| Line | Time (est.) |
|---|---|
| Expert best: Sky Line, Wild Line or Copper Line (§2.5) | **≈68–71 s**; about 2 s less with grinds |
| Clean strand lines with no skips (Blue / Teal / Rust) | ≈90–95 s |
| Average player | ≈95–110 s |
| The straight line ("just point it") | ≈100+ s, with high crash risk |

**Course size:**
- Length: 1500 m along Z.
- Width: 120 m at the apex, widening to ≈640 m at the toe.
- Total drop: ≈330 m.
- Path length: ≈1450–1650 m depending on line.

### 2.3 Layout Diagram (schematic, top-down)
- **Scale:** 1 character ≈ 20 m in X; 1 row ≈ 50 m in Z.
- **Schematic only:** ASCII forces straight lines. In the build, every strand, island and band curves and wanders as described in §2.4. Gates are the only straight lines.
- **Authoritative coordinates:** the tables in §2.4–2.11.
- **The straight line:** marked with `+` from Start (0, 0) to the finish arch (+80, −1480).

```
 z(m)  x: -360      -200      -40  0     +120      +280      +440
          |         |         |    |      |         |         |
    0     ^^^^^^^^^^^^^^^^^[==S==]^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   Z0 APEX  (mast*)
  -50     ^^^^^^^^^^^^^^^^/ . + . \^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 -100     ^^^^^^^^^^^^^^RW/  C+   \TE^^^^^^^^^^^^^^^^^^^^^^^^^^   D1 three mouths
 -150     ^^^^^^^^^^^R=cart   +    ))T ^^^^^^^^^^^^^^^^^^^^^^^^^   Z1 UPPER FAN
 -200     ^^^^^^^^^^R=     .  +  oo )T  ^^^^^^^^^^^^^^^^^^^^^^^
 -250     ^^^^^^^^^R    [PUMP]+oooo T   ^^^^^^^^^^^^^^^^^^^^^^^   D2 Pumphouse Island
 -300     ^^^^^^^^R      \  / +oo  T    ^^^^^^^^^^^^^^^^^^^^^^
 -350     ^^^^^^^^ R      ..  +  ))T     ^^^^^^^^^^^^^^^^^^^^^
 -400 ==S1=========== THE PAN (confluence) ===================   SPLIT 1
 -450     ^^^^^^ R\        C  +   T)       ^^^^^^^^^^^^^^^^^^^   D3 re-pick
 -500     ^^^^^ RR CHUTE   C  [LIFT]  TT     ^^^^^^^^^^^^^^^^^^   D4 Lift Island
 -550     ^^^^^ RR         C  [ISL ]+ TT     ^^^^^^^^^^^^^^^^^^   Teal Rapids
 -600     ^^^^^  RR        C   \gap/+ TT      ^^^^^^^^^^^^^^^^^
 -650     ^^^^ gg[R]gggggg[ford]gKggg+gggg[T]  ^^^^^^^^^^^^^^^^   D5 GRAVEL BAR
 -700     ^^^ R  [ORE ISL]  C  .   + #Gt TT    ^^^^^^^^^^^^^^^^   D6 Groove gap (#)
 -750     ^^^ R  [  =    ]  C rollers +G  TvvT*Needle ^^^^^^^^^   D7 Needle Drop
 -800     ^^^ R  [    =  ]  C  .   . + G   T      ^^^^^^^^^^^^^
 -850     ^^^  R          = C  .   .  +G    T     ^^^^^^^^^^^^^
 -900 ==S2=============== =BIG PAN ======+G==== T ===========   SPLIT 2
 -950     ^^^   M  .  .  .  .  .  . (arch)+   T [SPUR]  RIM ^^^   D8 dogleg choice
-1000     ^^^   M  .  .  .  .  . G .  .  +   T [SPUR]>RIM  ^^   Spur Transfer
-1050     ^^^   M  .  .  .  .  G  .  .  . +   T[SPUR]  RIM ^^
-1120     ^^^ SSSS XX[cul]XXX[HUCK]XXXXX+XXXX[RAMP]  RIM  ^^^   DRY FALLS BAND  D9
-1200     ^^^   M  .  .  .  . LAND .  .  . +  .  .     RIM ^^
-1250 ==S3=====================================+===============   SPLIT 3
-1300     ^^^    M  \\aqueduct  .  .  .  . [CHAPEL]  .  .  .  ^^   D10 Chapel Rock
-1350     ^^^     M  .  \\ .  .  .  .  .  . +  .  .  .  .  .  ^^
-1400     ^^^      .  .  .  .  .  .  .  .  .  +  .  .  .  .  ^^
-1480 ==================== F I N I S H  (arch at +80) ==========   FINISH (full width)
```
**Legend:**

| Symbol | Meaning |
|---|---|
| `S` / `F` | Start / finish |
| `===` | Full-width timing plane |
| `^` | Valley wall / out of bounds |
| `R`, `C`, `T` | Rust, Blue Crown, Teal strands |
| `M` | Meadow braid |
| `RIM` | East Rim strand |
| `G` | Long Groove (secret, sunken) |
| `o` | Boulder garden |
| `g` | Gravel bar |
| `[ ]` | Island or structure |
| `=` | Trestle or cart rail |
| `\\` | Aqueduct |
| `X` | No-go band face |
| `SSSS` | Stair Falls |
| `v` | Drop lip |
| `)` | Berm |
| `K` | Kicker |
| `#` | Rock-gap entry |
| `+` | The straight line |

### 2.4 Terrain Specification (for heightfield build)

**Composition:** **Y(x,z) = base(z) + crown(x,z) + margin(x,z) + Σ channels + Σ islands/bars + Σ steps + noise**

- All parameters live in a course data resource, not in code.
- **Grid:** 2 m. Extents x ∈ [−360, +420], z ∈ [+40, −1560], about 391 × 801 samples, chunked into 64 m tiles.
- **What the heightfield can't do:** vertical faces, overhangs, the rock arch and the culvert are **mesh primitives** placed on top. The heightfield under them stays sloped.
- **Engine check:** check heightfield collision against `docs/engine-reference/godot/` for the installed 4.7.2 before relying on it; this draft did not verify it.

**Base profile (along Z):**

| Zone | z from → to | Avg pitch | Base Y at end (≈) |
|---|---|---|---|
| Z0 Apex | 0 → −100 | 9° | −16 |
| Z1 Upper Fan | −100 → −400 | 14° | −91 |
| Z2 Mid Fan | −400 → −650 | 13° | −148 |
| Z3 Wide Fan | −650 → −900 | 12° | −201 |
| Z4 Dogleg | −900 → −1250 | 15°, plus the 12 m Dry Falls step at z ≈ −1120 | −307 |
| Z5 Toe | −1250 → −1500 | 6° easing to 3° | −330 |

**Fan axis and width:** the dogleg. Interpolate smoothly with a spline, not linearly.

| z | 0 | −100 | −400 | −650 | −900 | −1100 | −1250 | −1480 |
|---|---|---|---|---|---|---|---|---|
| axis x | 0 | −10 | −35 | −55 | −40 | +30 | +70 | +80 |
| width W | 120 | 160 | 300 | 420 | 560 | 600 | 620 | 640 |

**Crown term (convex fan):** crown = h_c·(1 − u²) for |u| ≤ 1, where u = (x − axis)/(W/2).
- h_c is 4 m at the top and grows to 8 m from z −650 down.
- Result: the centre is higher and gentler, and the side strands sit lower and steeper.

**Margin term (valley walls = natural boundary):** for |u| > 1, add (|u| − 1)·(W/2)·tan(40°), capped at +40 m.
- The wall surface is rough, then crash (rock) above +4 m.
- The wall line wanders ±15 m (noise, wavelength 150 m).

**Noise:**
- Large rolls: ±2.5 m, wavelength 80–150 m.
- Small undulations: ±0.4 m, wavelength 15–30 m.
- Fade the small layer to 0 within 20 m of any takeoff, landing or step-up.
- Tilt the cross-slope up to ±5° by zone so the fall line twists. Z1 tilts toward the west; Z4 tilts toward the east (the dogleg).

**Channels** (concrete floors; cosine cross-section; control points are spline knots; add lateral wander of ±8 m):

| ID | Strand | Control points (x, z) | Width / depth | Notes |
|---|---|---|---|---|
| CH-R1 | Rust upper | (−40,−90) (−110,−180) (−130,−280) (−80,−390) | 30 / 4 | 17–18° floor. Cart rail (G1) on the east bank, −120..−140 × −160..−300 |
| CH-R2 | Rust Chute | (−90,−430) (−180,−500) (−195,−580) (−150,−629) | 14 / 6 | **Steepest ground on the course: 21°** over z −470..−590. Bend radius ≥90 m. |
| CH-R3 | Ore strand | (−150,−640) (−225,−760) (−200,−860) (−90,−905) | 25 / 3 | Runs west around Ore Island |
| CH-C | Blue Crown | Follows the axis ±40 m: (0,−100) (−45,−250, west of the Pumphouse) (−50,−420) (−20,−540, west of Lift Island) (−60,−647, Crown Ford) (−40,−780) (−50,−900) (+40,−1000) (+160,−1120, The Ramp) (+100,−1300) (+80,−1480) | 60–90 concrete band / 0 | No channel: it rides the crown. Pump rollers in Z1 and Z3. **Long traverse east in Z4 (the dogleg tax).** |
| CH-T1 | Teal upper | (+45,−90) (+80,−180) (+55,−300) (+20,−390) | 30 / 3 | Two berms: (+80,−180) and (+55,−300), radius 45 m, bank 35° |
| CH-T2 | Teal Rapids | (+40,−430) (+110,−500) (+115,−620) (+120,−684, Teal slot) | 22 / 5 | 17–19°, with pop rollers |
| CH-T3 | Needle strand | (+130,−700) (+160,−770, drop) (+200,−880) (+210,−1000) (+170,−1100) → The Ramp | 25 / 4 | Hugs the east wall. Needle bend bypass at x +175..+200. |
| CH-G | **Long Groove** (secret) | (+90,−705) (+125,−800) (+100,−900) (+20,−1000) | **9 / 6** | Rock walls (mesh). 16° floor. Bend radius ≥150 m. Natural **rock arch** over it at (+55,−950), 20 m long. The only entry is the rock-gap roll-in at (+90,−705). Exit is a 3 m lip at (+20,−1000). |
| CH-E | East Rim | (+240,−1000) (+275,−1100) (+270,−1200) (+220,−1330) (+250,−1480) | 30 / 3 | 19° over −1000..−1200. Bypasses the Dry Falls band. Reached by the Spur Transfer, or by a slow rough crossing below the spur end. |
| CH-M | Meadow braid | (−120,−1150) (−80,−1280) (0,−1390) (+60,−1460) | 35 / 2 | Gentle. Aqueduct (G4) crosses it. |

**Islands, bars and spurs** (teardrop plan; rough top unless noted; rock-outcrop flanks are crash):

| ID | Feature | Centre / extent | Height | Built content |
|---|---|---|---|---|
| I1 | **Pumphouse Island** | (−10,−250); 30 × 50; x −25..+5, z −225..−275 | +3 m; concrete deck | Pumphouse (12×8×4 box); 3 step-ups on its uphill face; Pumphouse Gap lip at the downhill edge |
| I2 | Boulder Garden | (+25,−260); x +10..+40, z −230..−290 | +1 m | Boulders 1.5–3 m, gaps ≤2.5 m. **Crash field on the straight line.** |
| I3 | **Lift Island** | (+30,−540); 40 × 80; x +10..+50, z −500..−580 | +6 m | Chairlift mid-station; 4 step-ups on the uphill face; 50 m deck with a 5 m drop-in, then the Lift Line Gap kicker. Gravel-floored scour trough behind it, z −585..−610, exit ≤10°. |
| I4 | **Gravel Bar** | Spline (−220,−615) → (+150,−690); z_bar ≈ −615 − 0.203·(x+220) | +1.5 m, rough | 22 m wide at x 0 (Bar Hop), 40 m wide at x +40..+80 (on the straight line). Concrete cuts: Rust slot x −150 (8 m), **Crown Ford** x −60 (20 m concrete causeway), Teal slot x +120 (8 m). Cuts have 0.3 m curbs flared ≤10°. |
| I5 | **Ore Island** | (−160,−780); x −200..−120, z −715..−840 | +8 m | Mine ruins and headframe; crusher step-ups on the uphill face; **Trestle** launches from its uphill end |
| I6 | Groove rim | Strip each side of CH-G | +1 m, rough, with outcrops | Rock walls drop 6 m into the groove: crash anywhere except the entry gap |
| I7 | **East Spur** | Ridge x +200..+240, z −950..−1180 | Crest +8 m (+6 m above the Needle floor at the transfer) | Concrete bank on its west flank at (+205,−1000) for the Spur Transfer hip |
| I8 | **Chapel Rock** | (+80,−1330); x +60..+100, z −1310..−1350 | +5 m | Chapel, 3 terrace step-ups, Chapel Gap. The inn's flat roof is at (+80,−1370). |
| I9 | Scattered braid islets | 14–20 islets, 10–30 m long, in the crown (Z1–Z3) and the Meadow | +1–3 m, rough, outcrop noses | **Rule:** concrete lanes between islets ≥15 m wide, and no straight crown lane longer than 120 m. This forces carving. |

**Steps** (cliffs and bands; hard = mesh rock face):

| ID | Step | Position | Height | Passes |
|---|---|---|---|---|
| ST1 | **Dry Falls band** | Wavy line, nominal z −1120 (±20 m), x −230..+200 | 12 m | **Stair Falls** x −230..−170: 3 natural rock steps of 4 m onto concrete pads. **Culvert** at x −120: pipe through the face. **Huck** x −40..+20: concrete lip plus landing hill. **The Ramp** x +130..+190: softness 50 m, ≈28° concrete. **No-go:** x −170..−130, −110..−40 and **+20..+130**, which is where the straight line arrives. Hard faces with boulder talus below. |
| ST2 | Needle step | (+150..+175, −770) | 10 m hard | Bypass bend at x +175..+200 (softness 60 m) |
| ST3 | Apex rim | W mouth (−40,−90) | 2 m concrete roll-in | — |

**Straight-Line Test (design requirement):** the line from (0,0) to (+80,−1480) runs at x ≈ 0.054·|z|. It must hit the following obstacles, and it must stay slower than every strand line.

| z | x | What it hits |
|---|---|---|
| −250 | +14 | Boulder Garden (I2): crash |
| −540 | +29 | Lift Island's rock flank: crash or forced swerve |
| −668 | +36 | Gravel Bar at its 40 m-wide rough section: heavy slowdown |
| −700..−1000 | +38..+54 | The Groove's rough rim and the arch top: rough and slow |
| −1120 | +60 | Dry Falls **no-go** face: crash |
| −1330 | +72 | Chapel Rock flank |

### 2.5 Strands, Critical Path and Routes
Every route reaches the finish **without grinding**. Grind lines are marked **[GRIND]** and are always optional.

| Strand | Identity | Feel |
|---|---|---|
| **Blue Crown** (centre, main line) | Blue piste poles; wide rolling concrete under the chairlift | Safe, readable, pumpy, but gentle crown pitch and a long dogleg traverse |
| **Rust** (west) | Rust-orange square posts; cut concrete channels, mine relics, cart rails | Steep and fast in the chutes; precision and industrial features |
| **Teal** (east) | Teal triangle pennants on cairns; natural berms, rapids, the Needle spire | Flowing natural terrain, big berms, natural drops |
| Long Groove, East Rim, Meadow | Unmarked (Groove and Rim) or green-grass edged (Meadow) | Secret, wild, or relaxed connectors |

**Main line: Blue Crown** (≈92 s). This is the critical path: always available, always marked.
1. Blue mouth.
2. Around the west side of the Pumphouse.
3. The Pan (Split 1).
4. Down the crown, past the west side of Lift Island.
5. **Crown Ford** through the gravel bar.
6. The crown roller field.
7. Big Pan (Split 2).
8. Dogleg traverse east to **The Ramp**.
9. The toe, then the finish.

**Strand lines (normal):**
- **Rust** (≈95 s): W mouth → Rust upper → Pan → Rust Chute → Rust slot → Ore strand around Ore Island → Big Pan → **Stair Falls** → Meadow braid → finish.
- **Teal** (≈90 s): E mouth → Teal berms → Pan → Teal Rapids → Teal slot → Needle bend → Needle strand → The Ramp → toe → finish.

**Expert combos.** Each uses exactly one secret, so the three stay within ≈3 s of each other.

| Combo | Route | Time | Rewards |
|---|---|---|---|
| **Sky Line** (centre) | C mouth → **Pumphouse Gap** → Pan → **Lift Line Gap** → carve hard east into the **Long Groove** rock gap (secret) → Groove exit lines you up with the **Dry Falls Huck** → **Chapel Gap** → finish | ≈68 s | Nerve and line commitment |
| **Wild Line** (east) | E mouth → Teal berms → Teal Rapids → Teal slot → **Needle Drop** → **Spur Transfer** (secret) → East Rim, which bypasses the band → finish east of the arch | ≈70 s | Natural flow |
| **Copper Line** (west) | W mouth → Rust upper (+ cart rail [GRIND]) → Rust Chute → Rust slot → **Trestle Line** → Big Pan → **Culvert** (secret) → Meadow braid (+ Aqueduct [GRIND]) → finish | ≈71 s (≈69 with grinds) | Precision and alignment |

**Segment time estimates (s):**

| Line | Z0 | Z1 | Z2 | Z3 | Z4 | Z5 | Total |
|---|---|---|---|---|---|---|---|
| Blue Crown | 7 | 17 | 15 | 16 | 22 | 15 | ≈92 |
| Rust | 7 | 16.5 | 15 | 17.5 | 23 | 16 | ≈95 |
| Teal | 6.5 | 16 | 14.5 | 16 | 21.5 | 15.5 | ≈90 |
| Sky Line | 7 | 14.5 | 12 | 11.5 | 13 | 10 | ≈68 |
| Wild Line | 6 | 15 | 12.5 | 12 | 13.5 | 11 | ≈70 |
| Copper Line | 6.5 | 15 | 12.5 | 12.5 | 13.5 | 11 | ≈71 |

### 2.6 Decision Points (10)
Braid nodes are spaced 150–250 m apart, as on a real braided riverbed.

| # | Where (x, z) | Options | Tests |
|---|---|---|---|
| D1 | Apex mouths (−40..+45, −90) | **Rust** roll-in (2 m lip, steepest) · **Blue** (wide) · **Teal** (bank turn) | Commit to a strand |
| D2 | Pumphouse Island (−10, −225) | West around (main) · East around (squeezes past the Boulder Garden) · **Step-up + Pumphouse Gap** · (Rust riders: **cart rail [GRIND]**) | Step-up rhythm versus safe flow |
| D3 | The Pan (z −420) | Re-pick freely: **Rust Chute** · **Crown** · **Teal Rapids** | Recover or upgrade a line |
| D4 | Lift Island (+30, −500) | West around (main) · **Step-up + Lift Line Gap** · Teal Rapids alongside | Big placed air, with a speed check |
| D5 | Gravel Bar (z −630..−690) | Rust slot · **Crown Ford** · **Bar Hop** kicker (x 0) · Teal slot · ride the rough (slow) | Precision chokepoint versus air versus a cheap mistake |
| D6 | Below the bar (z −700) | **Trestle** step-up (Ore Island) · Ore strand around it · crown rollers · **Groove rock gap** (secret) · Needle strand | The biggest fork on the mountain |
| D7 | Needle (+150..+200, −770) | **Needle Drop** · Needle bend | Natural nerve |
| D8 | Big Pan (z −910) | Dogleg plan: west (Stair Falls / **Culvert**), centre (**Huck**), east (**Ramp**), far east (**Spur Transfer** → Rim) | Plan the band crossing |
| D9 | Dry Falls band (z −1000..−1120) | Stair Falls · Culvert · Huck · Ramp · Rim bypass | The biggest single time swing |
| D10 | Chapel Rock (+80, −1300) | **Chapel step-up + Gap** · **Aqueduct [GRIND]** · toe lane · Meadow braid | A last gamble before the finish |

### 2.7 Skips and Shortcuts ("Optional Paths")
Kinds: **N** = natural, **P** = placed, **G** = grind.

★ marks a big skip; there are 7.
- **No skip is marked** (§3.2). "Hinted" in the table below now means only that the feature is visible from its approach; there is no lip paint, chevron or crew tag.

| ID | Skip | Kind | Location | Skill needed | Saves (est.) | Risk / failure |
|---|---|---|---|---|---|---|
| S1 | Pumphouse Gap | P: step-up + gap · hinted | I1: 3 steps → deck → 16 m gap to a 25° landing bank at (−15, −292) | Chained hops; ≥15.5 m/s at the lip, or ≈12 m/s with full pop | ≈2 s | Short = gravel island tail, survived but slow |
| S2 | **Lift Line Gap** ★ | P: step-up + drop-in + kicker · hinted | I3: 4 steps → deck → 5 m drop-in → 3 m 22° kicker → 22 m gap over the scour trough to a landing bank at (+50, −625) | Chained hops; ≥19.8 m/s at the lip (the drop-in provides it) | ≈3 s | Short = the trough's rock lip = **crash** |
| S3 | Bar Hop | P: kicker · hinted | 2.4 m 22° concrete kicker at (0, −650), clears the 22 m bar | ≥19.9 m/s | ≈1.5 s versus the Ford | Short = onto the gravel, slow |
| S4 | **Trestle Line** ★ | P: step-up + elevated deck + gap · hinted | I5 crusher steps (4 × 1.0 m) → 4 m-wide deck from (−165, −730) straight to (−60, −890) at 11°, 175 m → broken end → 14 m gap to the Big Pan landing bank | Hop rhythm; holding a 4 m deck at ≈25 m/s; ≥18.8 m/s at the end | ≈5 s versus the Ore strand | Off the deck = 8–14 m fall onto rubble and ruins = crash. Short = rubble = crash. |
| S5 | **Long Groove** ★ | N: hidden gully · **secret** | Entry: a 7 m rock gap at (+90, −705); groove runs to (+20, −1000) | Hit the 7 m gap aligned at ≈24 m/s after carving from the Lift Line landing; hold 9 m width at ≈30 m/s | ≈5 s versus the crown rollers | Gap miss = rock = **crash**. Wall glance over ≈17° = crash. |
| S6 | **Needle Drop** ★ | N: drop · hinted | 10 m ledge (+150..+175, −770) onto a 32° landing | Blind drop at 14–26 m/s | ≈3 s versus the bend | Too slow = face = crash. Off-line = scree bench, survived. |
| S7 | **Dry Falls Huck** ★ | N lip + P landing · hinted | x −40..+20 at z ≈ −1120; 12 m onto a built 30° landing hill | Straight approach at 12–32 m/s | ≈7 s versus the Ramp traverse | Below ≈8 m/s = knuckle or face = crash. Drifting east = no-go face. |
| S8 | **Culvert** ★ | P: pipe · **secret** | Old flood culvert: concrete U-channel run-in (−120, −1060..−1090) → headwall → 4 m-diameter pipe, 50 m at 18° → exit at (−120, −1140) | Straight run-in aligned within ±1 m; hold the pipe centre at ≈26 m/s | ≈5 s versus Stair Falls or the traverse | Headwall = crash. Riding up the pipe wall: see Concerns. |
| S9 | **Spur Transfer** ★ | N: hip · **secret** | East Spur bank at (+205, −1000): ride the 30° bank up 6 m, hip the 3 m crest, land on a 30° far-side face into the East Rim | ≥21 m/s at the bank base (≥15.3 at the lip) | ≈3 s versus the Needle strand and Ramp | Short = spur crest rock = crash |
| S10 | Chapel Gap | P: step-up + pop gap · hinted | I8: 3 terraces (1.2 m) → 3.6 m terrace → 10° lip → 13 m gap to the inn's flat roof (2 m lower) → 1.6 m drop | Chained hops, plus **a pop at the lip** | ≈3 s versus the toe lane | No pop = 3.6 m drop into the lane, survived |
| G1 | Cart Rail [GRIND] | G | Old cart-track rail on the Rust bank, 140 m | Grind | ≈1 s | Fall = onto the channel, survived |
| G2 | Lift deck handrails [GRIND] | G | 2 × 30 m flanking the drop-in | Grind | Style; ≈0 s | — |
| G3 | Trestle edge rail [GRIND] | G | Along the deck edge, 175 m | Grind; frees steering on the narrow deck | ≈1 s | Fall off = crash (same as the deck) |
| G4 | Aqueduct [GRIND] | G | (−60, −1290) → (+40, −1420), 0.6 m off the ground at entry. 6 m arches keep the Meadow open underneath. | Grind | ≈2 s | Fall = 2–4 m, survived |

### 2.8 Checkpoints and Splits
- **Planes:** all gates are **full-width, full-height planes** from x −400 to +460 at all Y, including the groove and the culvert. No route can bypass them, and they must be crossed in order.
- **No funnel walls:** the finish is also a full-width line, so no rider has to swing in at a wall-hit angle.

| Gate | z | Visual | Respawn pads (x) |
|---|---|---|---|
| Start | 0 | Crew start hut and gate | 0 |
| Split 1 | −400 | Green and white flag towers across the Pan | −80 (Rust), −45 (Crown), +20 (Teal) |
| Split 2 | −900 | Flag towers across the Big Pan | −90, −50, +200 (Needle) |
| Split 3 | −1250 | Flag towers below the band | −80 (Meadow), +100, +260 (Rim) |
| Finish | −1480 | Painted line across the whole toe; arch over the main lane at x +80; flag towers every 60 m | — |

**Respawn:** this is an assumption, owned by systems.
- A crash respawns you at the pad nearest your crossing x, at ≈12 m/s, facing downhill, on clear concrete 15 m below the plane.
- The clock keeps running.
- Instant restart is always available.

### 2.9 Hazards and Crash Zones ("Encounter List")

| Hazard | Location | Why it crashes (vs skater numbers) | Telegraph |
|---|---|---|---|
| Boulder Garden | I2 (straight line, Z1) | Boulder contact = wall hit above 9 m/s | Red-tinted boulder faces; a red pennant cairn at the upstream nose |
| Island flanks and outcrop noses | Every island | Rock = wall hit | Red tint on the faces you could hit; rough skirt before the rock gives a warning slowdown |
| Lift scour trough lip | Behind I3 | Undershoot of the Lift Line Gap | Red stripe on the far lip; the trough floor exits at ≤10° (no softlock) |
| Trestle deck edges and broken end | S4 | 8–14 m fall onto ruins and rubble | Red deck-edge posts; red netting under the broken end |
| Groove rim and walls | CH-G | Rock walls; glance limit ≈17° at 30 m/s | None from above (it's secret). Inside: floor centreline worn pale. |
| Needle face | ST2 | Undershoot hits the face | Yellow lip, red face |
| Dry Falls no-go faces | ST1 (incl. x +20..+130 on the straight line) | A 12 m drop alone is survivable, so the **boulder talus below** (rocks ≤3 m apart) makes it a crash | Red and white chevron poles every 10 m, red netting along the lip |
| Culvert headwall | S8 | Head-on = crash | Yellow tag only; headwall has a red rim |
| Rough ground (gravel bar, islands, rims, meadow edges) | Everywhere between strands | Not a crash: heavy slowdown | Colour and texture change at the concrete edge, plus a 0.1 m curb lip |
| Valley walls | Fan margin | Rock above +4 m; out of bounds beyond | Ragged tree line, red fence along the contour |
| Trees | Clumps on islands and the margin | Trunk = wall hit | Minimum gap 3 m, so riders can't get wedged |

### 2.10 Pacing Chart (intensity 1–5 vs distance)

```
 5 |          *          *       * *  *              *               *
 4 |       * * *       * *     * *  *  *          * * *         * * *
 3 |  *  *       *   *       *          *   *   *       *   * *
 2 | *             *                      * *            * *
 1 |
   +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
   0  -100 -250 -400  -540 -650 -700 -770 -900 -1000 -1120 -1250 -1330 -1480
     apex PUMP  Pan   LIFT  BAR  GROOVE/  Big Pan  SPUR  DRY FALLS  CHAPEL FINISH
          (p1) (rest)  (p2)      TRESTLE/ (rest)        (peak 4)   (p5)
                                 NEEDLE (peak 3)
```
- **Rests:** the Pan (z −400, wide re-pick) and the Big Pan (z −900, re-plan for the band).
- **Peaks:** Pumphouse, Lift Island / Rust Chute, the D6–D7 cluster (Trestle, Groove, Needle), Dry Falls, then Chapel and the finish.
- **Main line:** never sits at 4–5 for more than ≈15 s.
- **Expert lines:** sustain 5 deliberately (the Groove is ≈11 s of it).

### 2.11 Feature Dimensions and Physics Sanity Checks

**Formulas** (tuning inputs; recompute whenever the physics thread changes the numbers):

1. **Gap clear onto a downslope.** Landing distance x_land = 2·v²·cosθ·(sinθ + cosθ·tanα) / g, so the minimum speed for a gap of length L is v_min = √(L·g / (2·cosθ·(sinθ + cosθ·tanα))).
   - v = takeoff speed; θ = lip angle; α = landing pitch; g = 18.
   - Pop adds to the vertical part: v_y = v·sinθ + pop.
2. **Gap onto a landing h below the lip.** Solve v_y·t − 9t² = −h, then x = v_x·t.
3. **Hop to a ledge of rise h.** Air time t = (pop + √(pop² − 2gh)) / g, and the tread must be ≥ v·t + 2 m.
   - Pop is the skater's own energy, so **step-ups don't cost horizontal speed.**
   - Keep each rise ≤ 1.2 m.
4. **Landing impact.** The normal component is v_n = |v|·sin(angle between the flight path and the surface); it must stay under 24 m/s.
   - That means ≈16 m drops onto flat ground are survivable, so **geometry, not height, has to punish.**
5. **Wall glance.** The safe angle is ≤ asin(9/v): 26° at 20 m/s, 19° at 27 m/s, 16° at 33 m/s.
   - Every curb, cut or channel entry flares ≤10–12°.
6. **Turn radius.** r = v/ω: ≈4 m at 10 m/s, ≈10 m at 20, ≈19 m at 27, ≈27 m at 32 (tuck makes it worse).
   - Fast-line bends must be ≥35 m; channel bends ≥40 m.
7. **Roller lift-off.** A rider leaves the ground when v² > g·R, where R = L²/(4π²·A) for a roller of length L and height A.
8. **Climbing a bank costs speed.** v_top = √(v² − 2gh).

| Feature | Dimensions | Check |
|---|---|---|
| Pumphouse step-ups | 3 × rise 1.0 m, tread 14 m | t ≈0.74 s at pop 8. At 14–16 m/s → 10–12 m ≤ 14 ✓ |
| Pumphouse Gap | Deck +3 m; 0.6 m 10° lip; 16 m to a 25° bank | 15.5 m/s → ≈15.1 m (marginal); 16 m/s → 16.7 m ✓. With pop 6 at 11 m/s → 15.3 m (marginal); at 12 m/s ✓ |
| Lift step-ups | 4 × 1.0 m, tread 16 m | 14–20 m/s → 10.4–14.8 m ✓ |
| Lift Line Gap | Drop-in 5 m (17 → ≈21.7 m/s); kicker 3 m 22°; 22 m to a knuckle 4 m below; landing face 30° | v_min ≈19.8 m/s (at 19.8, x ≈ 22.0) ✓ |
| Bar Hop | Kicker 2.4 m, 22°; bar 22 m + 2 m margin; α 13° | x = 0.0607·v², so v_min ≈19.9 m/s ✓ |
| Crown Ford / slots | 20 m / 8 m wide, 0.3 m curbs flared 10° | Glance limit at 25 m/s is 21° ✓ |
| Trestle | 4 m deck, 11°, 175 m; end gap 14 m to a knuckle 5 m below, face 30° | v_min ≈18.8 m/s; the deck builds ≈25 ✓. ±1.4 m drift margin (tight on purpose) |
| Ore crusher step-ups | 4 × 1.0 m, tread 16 m; approach on a 3° yard bench | ✓ (same as Lift) |
| Long Groove | 9 m wide, 6 m rock walls, 16° floor, bends ≥150 m, entry gap 7 m | At 30 m/s ω needed ≈0.2 rad/s ✓. Glance ≈17°. Entry: ±2.5 m lateral precision at ≈24 m/s (intended difficulty) |
| Groove carve-in | From the Lift landing (+50, −625) to the gap (+90, −705): 40 m lateral over 80 m | Needs a radius ≥40 m at ≈22 m/s (r_min ≈11) ✓ |
| Needle Drop | 10 m, 32° landing, 40 m long | At 20 m/s v_n ≈5.5 ✓. Flat bench miss: 19 m/s, survived ✓ |
| Dry Falls Huck | Lip at z ≈ −1120; knuckle 6 m out and 6 m below; 30° face 55 m, then 15° | 12 m/s lands past the knuckle ✓. At 22 m/s v_n ≈7 ✓. At 30 m/s near-parallel ✓ |
| Stair Falls | 3 × 4 m rock drops onto 15 m concrete pads at 20° | At 15 m/s v_n ≈6 ✓ |
| The Ramp | Softness 50 m, ≈28° | ✓ |
| Culvert | Run-in 30 m U-channel flared 10°; pipe Ø 4 m, 50 m, 18° | Exit ≈26 m/s. **Pipe walls must count as ground, not wall** (Concerns) |
| Spur Transfer | 30° bank, +6 m, 3 m crest, 10 m to a 30° far-side face, 25° lip | v_lip ≥15.3 m/s, so ≥21 m/s at the base (√(21² − 216) ≈ 15.4) ✓ |
| Chapel step-ups / Gap | 3 × 1.2 m, tread 13 m; 10° lip, 13 m, landing −2 m | t ≈0.70 s, 15 m/s → 10.5 m ✓. No pop at 14 m/s → 8.6 m ✗ (bail); pop 6 → 15.6 m ✓ |
| Pump rollers (crown) | A 0.75 m, L 30 m (R ≈30 m) | Stay grounded up to ≈23 m/s ✓ |
| Pop rollers (Teal Rapids, Meadow) | A 1.0 m, L 14 m (R ≈5 m) | Lift off above ≈9.5 m/s ✓ |
| Teal berms | Radius 45 m, bank 35° | ≥ the 27–32 m/s turn radius ✓ |
| Rust Chute | 14 m wide, 21°, bend radius ≥90 m | At tucked ≈33 m/s, ω needed 0.37 ✓ |
| Rails (G1–G4) | 0.4 m box or round, 0.6 m off the ground at entry; nothing to hop onto above 1.0 m | Max hop 1.8 m ✓ |
| Islets / trees | Lanes ≥15 m; tree gaps ≥3 m; no straight crown lane >120 m | — |

### 2.12 Landmarks, Wayfinding and Colour Cues

**Wayfinding rule (revised 2026-11-04, §3.2):** lines are not marked. Every braid node (D1–D10) shows each option's *terrain and landmark* at least 3 s ahead (≈75 m at 25 m/s); the player reads the ground, not paint or poles. Islands sit below eye height at nodes, so the fan reads as one open space.

| Landmark | Position | Guides |
|---|---|---|
| Summit radio mast | Behind the start | Orientation at the start |
| **Chairlift line** | Along the crown, apex to toe | **The Blue Crown's leading line**: "follow the chairs" |
| Pumphouse | I1 | First island; shows the step-up and gap language |
| Lift Island station | I3 | Blue/centre mid-point |
| **Copper headframe** (40 m, rust orange) | Ore Island | **Rust's beacon**, visible from the apex |
| **The Needle** (35 m spire) | (+200, −760) on the east wall | **Teal's beacon** |
| East Spur | I7 | The Rim side |
| Chapel spire | I8 | Visible from the Big Pan; the toe target |
| Finish arch | (+80, −1480) | Visible from Split 3 |

**Strand identity** (feature language only; the marker column is SUPERSEDED by §3.2 and was removed from the build):

| Strand | ~~Marker~~ | Feature language |
|---|---|---|
| Blue Crown | Blue round-top poles | Wide rollers, chairlift overhead |
| Rust | Rust-orange square posts, cart rails, lanterns | Cut channels, industrial |
| Teal | Teal triangular pennants on cairns | Berms and natural rock |
| Meadow | Green grass edges | — |
| Secret lines (Groove, Rim) | Unmarked except yellow crew tags | — |

**Shared colour language** (fixed across courses, §0.2):

| Meaning | Colour | Shape |
|---|---|---|
| ~~Skip takeoff~~ | ~~Yellow lip paint~~ | Removed (§3.2): takeoffs are plain concrete |
| Hazard / crash | Red, red/white | Downward chevrons, netting |
| Checkpoint / finish | Green and white | Flag towers, arch |
| Out of bounds | Red fence | Fence plus tree wall |

**Ground palette** (the surface must read at speed):
- **Concrete** is the brightest, smoothest ground on screen: light warm pale grey, with expansion joints running *along* each strand's fall line as speed lines.
- **Rough** is darker and textured: gravel mid-grey speckle, grass green, dirt brown.
- **Crash rock** is dark faceted grey with a red tint on hittable faces.
- **"Bright = fast"** holds in colour-blind modes.
- Red is reserved for hazards, so roofs are slate grey.

### 2.13 Narrative Beats (light; environmental only)
- **Apex:** the crew's start hut, with a run board showing three faded chalk lines (Sky, Wild, Copper) that start but don't finish.
- **Ore Island:** ruins and a broken trestle end with skid marks on the landing bank.
- **Long Groove:** crew tags and an old sticker-covered sign inside: "you found it".
- **Culvert:** a flood marker and painted arrows.
- **Chapel:** the bell rings on a personal best.

### 2.14 Music and Audio Cues
| Moment | Cue |
|---|---|
| Apex | Wind and the hum of the radio mast. Music low, percussion only. |
| Speed | Wind roar scales with speed; there's an extra layer when tucked above 30 m/s. |
| Strand identity | **Rust:** metal ticks and creaks. **Crown:** chairlift pulley clatter overhead. **Teal:** open air and falling scree. Each crossfades as you change strand, so strand identity is audible too. |
| Approaching any drop lip | A wind-gust "falloff" sound 1.5 s before the lip (audio telegraph). |
| Gravel and rough ground | A harsh rattle; music ducks slightly as a "you're slow" signal. |
| Groove / Culvert | Tight reverb and wheel roar off the walls; in the culvert, a hollow pipe drone. |
| Split gates | A chime, then a rising two-note tone when ahead of your best or a falling one when behind. |
| Big Pan | Music drops a layer (rest beat). |
| Dry Falls | Music builds and peaks at the lip. |
| Finish | Crowd swell, then the chapel bell on a personal best. |

### 2.15 Systems Notes (routed through level design; not decided here)
- **Surfaces:** a per-surface lookup is needed from the physics thread. Draft values:

  | Surface | Drag | Steering | Other |
  |---|---|---|---|
  | Concrete | 1× | Normal | — |
  | Grass / dirt | ≈4× | −20% | — |
  | Gravel | ≈3× | −35% | Wobble |
  | Rock / trunk / wall | — | — | Crash |

  Rough drag must never stop a rider who is pushing (push should still hold ≥4 m/s on rough ground).
- **Respawn:** see §2.8 (assumption).
- **Data-driven geometry:** every row in §2.4 and §2.11 is a course-resource value. Skip validity should be re-checked automatically by the §2.11 formulas whenever the skater tuning changes.

### 2.16 QA

**Sequence-break risks**
1. **The straight line:** run the Straight-Line Test (§2.4) every build. The straight line must stay slower than Blue Crown.
2. **Groove entries:** confirm there's no unintended entry. The rim walls must be crash everywhere except the gap, and the arch must be solid.
3. **East Rim bypass:** the Rim bypasses the Dry Falls band entirely (intended). Confirm a rough crossing to the Rim without the Spur Transfer is slower than the Ramp.
4. **Island tops:** riding across islands (rough) is legal. Check that no rough shortcut beats a concrete strand.
5. **Valley walls:** check they can't be ridden as wallrides (≥40°, rough, then rock).
6. **Gates:** gates are full-height planes; verify the Groove, Culvert and Trestle flight all register in order.
7. **Combo balance:** confirm the three expert combos stay within ≈3 s of each other and that no two-secret combo is possible by accident.

**Softlock risks**
1. **Gravel bar:** at push speed with rough drag, a rider must still cross the 1.5 m bar. Fords and slots are always ≤60 m away along the bar.
2. **Scour trough behind Lift Island:** exit slope ≤10° downstream.
3. **Island decks and terraces:** every one has a drop-off ≤4 m to riding ground, except the Trestle (crash by design).
4. **Groove and culvert:** continuously downhill; no flats.
5. **Flats:** pans and the toe sit at ≥6° (≥3° only in the final run-out). Push always moves you.
6. **Trees and islets:** gaps ≥3 m, so riders can't get wedged.

**Out-of-bounds handling:** the kill volume triggers on any of these, and respawns you at the last gate's pad:
- |u| > 1.25 (beyond the valley walls);
- x outside [−360, +420];
- z > +30 or z < −1540;
- Y more than 10 m below the terrain surface, or any Y < −380.

The red fence on the wall contour warns about 15 m before the kill line.

**Playtest checklist**
- [ ] All 6 lines (Blue, Rust, Teal, Sky, Wild, Copper) completed clean, **without grinding**.
- [ ] Measured times against §2.5. Experts land at ≈65–75 s and normal lines at ≈90–100 s. The straight line is slower than Blue.
- [ ] Each skip tested at its minimum, mid and maximum speed, with the failure mode matching §2.7.
- [ ] Fresh players can name all three strands by colour after one run, and say which landmark belongs to which.
- [ ] Fresh players do *not* find any secret on their first three runs; testers who are told "there's a hidden gully" find the Groove within about 10 runs.
- [ ] Naturalness pass: an overhead capture shows no straight or grid-aligned terrain; the fan reads as one braided landform.
- [ ] Surface read: riders can tell concrete from rough at full speed.
- [ ] Every crash feels fair; a stop-and-push test at each softlock site passes.
- [ ] Colour-blind simulation pass.
- [ ] Run-and-observe screenshots retained in `production/qa/evidence/`.

---

## 3. Resolved Questions
1. **Straight line slow and crashy?** Yes (Conner, 2026-11-04): "you should not be able to go straight down. This should be a hard game where you're forced to find creative lines." Keep the Straight-Line Test as a hard requirement; difficulty bias is toward demanding lines.
2. **Mark the lines?** No (Conner, 2026-11-04): "we should not be marking lines, they should be emergent for the player to discover, and they should have lots of options to cross over and test different paths." Rule for every course:
   - No strand poles, coloured markers, lip paint, chevrons or crew tags.
   - Kept, because they are not route hints: red hazard tint (fairness, a crash must be readable), green/white checkpoint towers and the finish arch, landmarks and the chairlift as scenery.
   - Lines must cross often: at least one crossover per split section linking neighbouring strands, so a rider can switch lines mid-run and test combinations.

---

## 4. Build Notes: greybox v1 (2026-11-04)

Built from `assets/data/course_copperline_mountain.json` (schema: `docs/course-data-schema.md`). Differences from the layout above, all tuning-level:

- **Measured times (bot, new skater physics, no skips):** Blue ≈1:27, Teal ≈1:39, Rust ≈2:05. Rust is slow where the bot stalls on rough ground; re-check with a human.
- **Blue Crown dogleg** crosses below the Long Groove exit (0, −1010) and traverses east to The Ramp at z −1035..−1095, because a late traverse launched riders sideways off the band.
- **Island heights match their step-ups:** Lift Island +4 m (4 steps), Ore Island +4 m (crusher steps lead onto the Trestle, which now runs (−150, −730) → (−95, −885)). No 5 m drop-in on Lift Island.
- **Ore strand** swings west earlier ((−200, −685)) so it clears the crusher steps, and ends at (−115, −912) to clear the Trestle landing.
- **Landings are sloped** for the new physics (landing impact limit 11 m/s): Needle Drop 3 m face then a 33° landing; Dry Falls Huck 3 m knuckle then a 36 m, ≈29° landing face, no kicker (paint only); Stair Falls is three 3 m rolls instead of 4 m drops.
- **Culvert** is an open slot sunk 12 m through the band (no pipe roof yet). **Teal Rapids** starts at (+55, −425) and the Teal Split 1 pad is at x +50, clear of the Lift step-ups.
- **Emergent lines (§3.2):** strand marker poles and yellow kicker paint removed. Eight concrete crossover bands link the strands: X1 Rust→Crown (z −200..−230), X2 Crown→Teal (−180..−200), X3 Rust↔Crown↔Teal (≈−320), X8 Crown↔Teal (≈−700), X7 Ore↔Crown (−830..−852), X10 Culvert↔Crown (≈−995), X12 Huck↔Meadow↔Ramp (≈−1250), X13 Meadow↔Rim (≈−1330). A mixed line (Rust → X3 → Teal → Meadow → Ramp) rides clean; the main three lines' times are unchanged (Blue 1:27, Teal 1:39, Rust 2:04).
- **Not built yet:** Chapel bell, audio cues, the rock-gap entry dressing for the Groove, the 12 m/s respawn speed (respawn is stopped and waits for input), grinding on the rails.
