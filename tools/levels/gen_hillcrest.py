#!/usr/bin/env python3
"""Generate assets/data/course_hillcrest_drop.json, the Hillcrest Drop city course.

Design: design/levels/hillcrest-drop.md. Every number that shapes the level
(street grid, intersection heights, lips, skips, crowds, traffic) is a named
constant or table below; the script turns them into course data the shared
level kit builds (docs/course-data-schema.md). Re-run after editing:

    python3 tools/levels/gen_hillcrest.py

Deterministic: a fixed seed, so the same script always writes the same file.
Conventions as every course: metres, downhill = -Z, +X = right looking downhill.
"""
import json
import math
import os
import random

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "data", "course_hillcrest_drop.json")

# --- Street grid (design doc: Layout) -------------------------------------
ROAD = 12.0            # curb to curb
SIDEWALK = 3.5
HALF = ROAD / 2 + SIDEWALK   # street centre to building line (9.5)
COLS = [("Quarry St", -250.0), ("Vesper St", -125.0), ("Hillcrest Ave", 0.0),
        ("Juniper St", 125.0), ("Tidewater St", 250.0)]
ROWS = [("Crest Way", -40.0), ("Alta St", -150.0), ("Sacra St", -260.0),
        ("Pine Terrace", -370.0), ("Larch St", -480.0), ("Fogline St", -590.0),
        ("Wharf Hill St", -700.0), ("Lower Court", -810.0), ("Shore St", -920.0)]
PROM_Z = -1000.0       # Bayfront promenade centre line
PROM_W = 26.0
PROM_Y = -112.0
SEAWALL_Z = PROM_Z - PROM_W / 2   # -1013
WATER_Y = -114.5

# Intersection heights (y) per row, per column (Quarry .. Tidewater).
LEVELS = [
    [-6, -3, 0, -3, -6],          # Crest Way
    [-17, -18, -15, -14, -15],    # Alta
    [-30, -42, -33, -28, -26],    # Sacra  (Vesper 1->2 is "The Wall", 26%)
    [-44, -50, -50, -42, -38],    # Pine Terrace (house jump at Hillcrest)
    [-58, -64, -70, -56, -50],    # Larch
    [-72, -80, -84, -70, -66],    # Fogline
    [-86, -93, -96, -90, -80],    # Wharf Hill (Juniper 5->6 steep, 22%)
    [-97, -103, -104, -98, -92],  # Lower Court
    [-105, -109, -109, -104, -100],  # Shore
]

# Crown lips at the downhill exit of an intersection: (lip height, lip length).
LIP = (0.35, 5.0)
BIG_LIP = (0.75, 6.0)
BIG_LIPS = {(1, 1), (1, 2), (4, 3), (2, 4), (5, 0), (0, 2), (6, 1)}  # (row, col)

# --- Signature skip: the House Jump at Pine Terrace / Hillcrest -------------
TERRACE_ROW = 3
HOUSE = {"p": [0.0, -389.0], "s": [17.0, 0.0, 15.0], "top": -51.0, "c": "#e8d9b5"}
DRIVEWAY = {"at": [0.0, -371.5], "length": 4.0, "height": 0.8, "width": 5.0}
LOWER_TOP_Z = -399.0
LOWER_TOP_Y = -56.0
LOWER_STEEP = 0.30
LOWER_STEEP_END = -445.0
# The slower way round: a steep switchback ramp off the terrace.
TERRACE_RAMP = [[22.0, -379.0, -50.0], [24.0, -391.0, -53.0], [14.0, -402.0, -56.6], [5.0, -405.0, -57.5]]

# --- Hillcrest Steps (Hillcrest Ave, Fogline -> Wharf Hill) -------------------
STEPS_ROW = 5
STEP_FLIGHTS = 11
STEP_RISERS = 6
STEP_TREAD = 0.48
STEP_WIDTH = 15.0     # whole stairway: stairs plus the smooth runway beside them
STEP_RUNWAY = 4.5     # smooth sloped runway on the right: the slow way down, no gapping needed
STEP_SINK = 0.05      # step tops sit this far under the street so you roll off, never into, an edge

# --- Alleys and lanes: narrow crossovers between streets --------------------
ALLEYS = [
    {"id": "lantern_alley", "from": (1, 1), "to": (2, 2), "width": 6.0},
    {"id": "mint_alley", "from": (1, 4), "to": (2, 3), "width": 6.0},
    {"id": "fog_alley", "from": (4, 3), "to": (5, 2), "width": 6.0},
    {"id": "cannery_cut", "from": (6, 2), "to": (7, 1), "width": 6.0},
    {"id": "rope_alley", "from": (3, 0), "to": (4, 1), "width": 5.5},
    {"id": "tar_alley", "from": (7, 4), "to": (8, 3), "width": 5.5},
]
LANES = [  # straight mid-block lanes between two rows at a fixed x
    {"id": "sailors_lane", "x": 187.0, "rows": (6, 7), "width": 5.0},
    {"id": "pinch_lane", "x": -62.0, "rows": (4, 5), "width": 4.5},
    {"id": "bakers_lane", "x": -187.0, "rows": (1, 2), "width": 5.0},
    {"id": "kite_lane", "x": 62.0, "rows": (7, 8), "width": 4.5},
]

# --- Pier finish -----------------------------------------------------------------
PIER_X = 0.0
PIER_END_Z = -1104.0
PIER_W = 12.0
FINISH_Z = -1102.5

# --- Traffic and crowds ---------------------------------------------------------
CROSS_TRAFFIC_ROWS = {1: (8.5, 0.0), 4: (9.0, 3.0), 6: (8.0, 7.0), 8: (9.5, 1.5)}  # row: (speed, phase)
CABLE_CAR_COL = 3
SEED = 4242

PALETTE = ["#e8d9b5", "#c9d6df", "#f2c6b4", "#b5d3b0", "#f3e3a1", "#d8c3e0", "#a9c4d8",
           "#efefe6", "#d9a38f", "#9fb8a7", "#e6b8c2", "#c8b79a"]
DOWNTOWN = ["#9aa3ad", "#b8b2a6", "#7f8a94", "#c3c7cc", "#a39686"]
CAR_COLORS = ["#c0392b", "#2c3e50", "#ecf0f1", "#2980b9", "#7f8c8d", "#16a085", "#8e44ad", "#d35400", "#1c1c1c"]

rng = random.Random(SEED)


def level(r, c):
    return float(LEVELS[r][c])


def row_z(r):
    return ROWS[r][1]


def col_x(c):
    return COLS[c][1]


def node(r, c):
    return (col_x(c), row_z(r), level(r, c))


def cross_y(r, x):
    """Height of cross street r at x (level within intersections, linear between)."""
    xs = [col_x(c) for c in range(len(COLS))]
    for c in range(len(xs)):
        if abs(x - xs[c]) <= HALF:
            return level(r, c)
    if x < xs[0]:
        return level(r, 0)
    if x > xs[-1]:
        return level(r, len(xs) - 1)
    for c in range(len(xs) - 1):
        a = xs[c] + HALF
        b = xs[c + 1] - HALF
        if a <= x <= b:
            t = (x - a) / (b - a)
            return level(r, c) + t * (level(r, c + 1) - level(r, c))
    return level(r, 0)


def block_profile(c, r):
    """Points [x, z, y] down column c from row r's downhill edge to the next row's uphill edge."""
    x = col_x(c)
    z0 = row_z(r) - HALF
    y0 = level(r, c)
    if r + 1 < len(ROWS):
        z3 = row_z(r + 1) + HALF
        y3 = level(r + 1, c)
    else:
        z3 = PROM_Z + PROM_W / 2
        y3 = PROM_Y
    lip_h, lip_l = BIG_LIP if (r, c) in BIG_LIPS else LIP
    z1 = z0 - lip_l
    y1 = y0 + lip_h
    run = z1 - z3
    grade = (y1 - y3) / run
    z2 = z3 + 8.0
    y2 = y3 + 0.5 * 8.0 * grade
    return [[x, z0, y0], [x, z1, y1], [x, z2, y2], [x, z3, y3]]


# --- Corridors (alleys, lanes, ramp): kept clear of buildings and sidewalks ----
corridors = []   # (list of (x, z), half width)


def seg_dist(p, a, b):
    ax, az = a
    bx, bz = b
    px, pz = p
    dx, dz = bx - ax, bz - az
    L2 = dx * dx + dz * dz
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / L2))
    qx, qz = ax + t * dx, az + t * dz
    return math.hypot(px - qx, pz - qz)


def corridor_dist(p):
    best = 1e9
    for pts, half in corridors:
        for i in range(len(pts) - 1):
            best = min(best, seg_dist(p, pts[i], pts[i + 1]) - half)
    return best


def blocked(p, clearance):
    return corridor_dist(p) < clearance


# --- Build ---------------------------------------------------------------------
streets = []
features = []
routes = {}

# Alleys and lanes first; streets stamped later win at the ends.
for a in ALLEYS:
    pa = node(*a["from"])
    pb = node(*a["to"])
    streets.append({"id": a["id"], "points": [list(pa), list(pb)], "width": a["width"], "feather": 3.0})
    corridors.append(([(pa[0], pa[1]), (pb[0], pb[1])], a["width"] / 2))
for ln in LANES:
    r0, r1 = ln["rows"]
    x = ln["x"]
    za, zb = row_z(r0), row_z(r1)
    streets.append({"id": ln["id"], "points": [[x, za, cross_y(r0, x)], [x, zb, cross_y(r1, x)]],
                    "width": ln["width"], "feather": 3.0})
    corridors.append(([(x, za), (x, zb)], ln["width"] / 2))
streets.append({"id": "terrace_ramp", "points": TERRACE_RAMP, "width": 7.0, "feather": 3.0})
corridors.append(([(p[0], p[1]) for p in TERRACE_RAMP], 3.5))

# Summit plaza and the drop-in down to Crest Way.
streets.append({"id": "summit_plaza", "points": [[0, 62, 9], [0, 22, 9]], "width": 34.0, "feather": 8.0})
streets.append({"id": "drop_in", "points": [[0, 22, 9], [0, 14, 8.2], [0, -22.5, 1.0], [0, -30.5, 0.0]],
                "width": ROAD + 2 * SIDEWALK, "feather": 6.0})

# Downhill streets, block by block.
for c in range(len(COLS)):
    for r in range(len(ROWS)):
        x = col_x(c)
        if c == 2 and r == TERRACE_ROW:
            # Lower Hillcrest: starts below the jump house, steep, then eases out.
            z_end = row_z(r + 1) + HALF
            y_steep = LOWER_TOP_Y - LOWER_STEEP * (LOWER_TOP_Z - LOWER_STEEP_END)
            pts = [[x, LOWER_TOP_Z, LOWER_TOP_Y], [x, LOWER_STEEP_END, y_steep],
                   [x, LOWER_STEEP_END - 8, (y_steep + level(r + 1, c)) / 2], [x, z_end, level(r + 1, c)]]
            streets.append({"id": "lower_hillcrest", "points": pts, "width": ROAD + 2 * SIDEWALK, "feather": 4.0})
            continue
        if c == 2 and r == STEPS_ROW:
            z0 = row_z(r) - HALF
            z1 = row_z(r + 1) + HALF
            streets.append({"id": "hillcrest_steps_bed", "points": [[x, z0, level(r, c) - 1.0], [x, z1, level(r + 1, c) - 1.0]],
                            "width": STEP_WIDTH + 3.2, "feather": 2.0})
            continue
        streets.append({"id": "%s_%d" % (COLS[c][0].split()[0].lower(), r), "points": block_profile(c, r),
                        "width": ROAD + 2 * SIDEWALK, "feather": 6.0})

# Cross streets (level inside intersections), then the promenade.
for r in range(len(ROWS)):
    pts = [[-262.0, row_z(r), level(r, 0)]]
    for c in range(len(COLS)):
        pts.append([col_x(c) - HALF, row_z(r), level(r, c)])
        pts.append([col_x(c) + HALF, row_z(r), level(r, c)])
    pts.append([262.0, row_z(r), level(r, len(COLS) - 1)])
    streets.append({"id": ROWS[r][0].lower().replace(" ", "_"), "points": pts, "width": ROAD + 2 * SIDEWALK, "feather": 6.0})
streets.append({"id": "bayfront", "points": [[-330, PROM_Z, PROM_Y], [330, PROM_Z, PROM_Y]], "width": PROM_W, "feather": 2.0})

# --- Sidewalks (raised slabs), cut where a corridor crosses ---------------------
sidewalk_ramps = []


def add_sidewalk(a, b, ya, yb):
    """Sidewalk slab a->b (x, z) with top heights ya, yb (street + curb), split around corridors."""
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    if L < 0.5:
        return
    n = max(2, int(L / 1.0))
    run_start = None
    for i in range(n + 1):
        t = i / n
        p = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
        free = not blocked(p, 1.5)
        if free and run_start is None:
            run_start = t
        if (not free or i == n) and run_start is not None:
            t_end = t if free else (i - 1) / n
            if (t_end - run_start) * L > 1.0:
                pa = (a[0] + (b[0] - a[0]) * run_start, a[1] + (b[1] - a[1]) * run_start)
                pb = (a[0] + (b[0] - a[0]) * t_end, a[1] + (b[1] - a[1]) * t_end)
                sidewalk_ramps.append({"type": "ramp", "a": [round(pa[0], 2), round(pa[1], 2)], "b": [round(pb[0], 2), round(pb[1], 2)],
                                       "lift_a": round(ya + (yb - ya) * run_start + 0.15, 3),
                                       "lift_b": round(ya + (yb - ya) * t_end + 0.15, 3),
                                       "width": SIDEWALK, "thickness": 0.8, "kind": "#b9b5ad", "plane": "abs"})
            run_start = None


SW_OFF = ROAD / 2 + SIDEWALK / 2
for s in streets:
    sid = s["id"]
    pts = s["points"]
    is_cross = any(sid == r[0].lower().replace(" ", "_") for r in ROWS)
    is_block = sid.split("_")[0] in [c[0].split()[0].lower() for c in COLS] and sid.split("_")[-1].isdigit()
    if is_block or sid in ("lower_hillcrest", "drop_in"):
        for side in (-1, 1):
            for i in range(len(pts) - 1):
                a, b = pts[i], pts[i + 1]
                add_sidewalk((a[0] + side * SW_OFF, a[1]), (b[0] + side * SW_OFF, b[1]), a[2], b[2])
    elif is_cross:
        for side in (-1, 1):
            z = pts[0][1] + side * SW_OFF
            for c in range(len(COLS) - 1):
                xa = col_x(c) + HALF
                xb = col_x(c + 1) - HALF
                r = [i for i, rr in enumerate(ROWS) if rr[0].lower().replace(" ", "_") == sid][0]
                add_sidewalk((xa, z), (xb, z), level(r, c), level(r, c + 1))
# Promenade: inland sidewalk only, open at every street mouth; the seaward
# edge is the seawall rail.
_edges = [-330.0] + [v for c in COLS for v in (c[1] - HALF, c[1] + HALF)] + [330.0]
for k in range(0, len(_edges), 2):
    add_sidewalk((_edges[k], PROM_Z + PROM_W / 2 - 1.75), (_edges[k + 1], PROM_Z + PROM_W / 2 - 1.75), PROM_Y, PROM_Y)
features += sidewalk_ramps

# --- Buildings -------------------------------------------------------------------
houses = []
downtown = []


def lot_row(x0, x1, z0, z1, along_x, depth_dir, depth=16.0, tall=False):
    """Fill a frontage from (x0,z0) to (x1,z1) with lots of random width.
    along_x: frontage runs along X. depth_dir: +1/-1 direction the lot extends away from the street."""
    length = abs(x1 - x0) if along_x else abs(z1 - z0)
    s = 0.0
    while s < length - 3.0:
        w = min(rng.uniform(6.5, 10.0), length - s)
        mid = s + w / 2
        if along_x:
            x = min(x0, x1) + mid
            z = z0 + depth_dir * depth / 2
            size = [w - 0.3, 0, depth]
        else:
            x = x0 + depth_dir * depth / 2
            z = max(z0, z1) - mid
            size = [depth, 0, w - 0.3]
        p = (x, z)
        # Keep corridors and the jump house clear.
        if not blocked(p, max(size[0], size[2]) / 2 + 1.0) and not (abs(x - HOUSE["p"][0]) < 14 and abs(z - HOUSE["p"][1]) < 12):
            if tall:
                h = rng.uniform(18.0, 46.0)
                downtown.append({"p": [round(x, 2), round(z, 2)], "s": [round(size[0], 2), round(h, 1), round(size[2], 2)],
                                 "c": rng.choice(DOWNTOWN)})
            else:
                h = rng.choice([7.5, 9.0, 10.5, 12.0, 13.5])
                houses.append({"p": [round(x, 2), round(z, 2)], "s": [round(size[0], 2), h, round(size[2], 2)],
                               "c": rng.choice(PALETTE)})
        s += w


DEPTH = 16.0
xs = [col_x(c) for c in range(len(COLS))]
row_edges = [row_z(r) for r in range(len(ROWS))] + [PROM_Z]
for r in range(len(ROWS)):
    z_top = row_z(r) - HALF
    z_bot = (row_z(r + 1) + HALF) if r + 1 < len(ROWS) else PROM_Z + PROM_W / 2
    for c in range(len(COLS) - 1):
        xa = xs[c] + HALF
        xb = xs[c + 1] - HALF
        tall = (c <= 1 and r >= 6)
        # Frontages on the two downhill streets (full block length).
        lot_row(xa, xa, z_top, z_bot, False, +1, DEPTH, tall)
        lot_row(xb, xb, z_top, z_bot, False, -1, DEPTH, tall)
        # Frontages on the two cross streets (between the side rows).
        lot_row(xa + DEPTH, xb - DEPTH, z_top, z_top, True, -1, DEPTH, tall)
        lot_row(xa + DEPTH, xb - DEPTH, z_bot, z_bot, True, +1, DEPTH, tall)
    # Outer edges of the grid.
    lot_row(xs[0] - HALF, xs[0] - HALF, z_top, z_bot, False, -1, 40.0, r >= 6)
    lot_row(xs[-1] + HALF, xs[-1] + HALF, z_top, z_bot, False, +1, 40.0, False)
# North side of Crest Way, either side of the summit park.
for xa, xb in ((-300.0, -40.0), (40.0, 300.0)):
    lot_row(xa, xb, row_z(0) + HALF, row_z(0) + HALF, True, +1, DEPTH)
# Hillcrest Ave above Crest Way (the drop-in) is lined with houses too.
lot_row(-HALF, -HALF, 14.0, row_z(0) + HALF + DEPTH, False, -1, DEPTH)
lot_row(HALF, HALF, 14.0, row_z(0) + HALF + DEPTH, False, +1, DEPTH)

houses.append(dict(HOUSE))   # the jump house, roof below the terrace
features.append({"type": "solids", "id": "houses", "style": "building", "items": houses})
features.append({"type": "solids", "id": "downtown", "style": "building", "items": downtown})

# --- The House Jump driveway (plain concrete, unmarked) --------------------------
features.append({"type": "kicker", "id": "terrace_driveway", "at": DRIVEWAY["at"], "heading": 0,
                 "length": DRIVEWAY["length"], "height": DRIVEWAY["height"], "width": DRIVEWAY["width"], "kind": "#b9b5ad"})

# --- Hillcrest Steps ---------------------------------------------------------------
x = col_x(2)
z = row_z(STEPS_ROW) - HALF
y = level(STEPS_ROW, 2)
z_end = row_z(STEPS_ROW + 1) + HALF
landing = (abs(z_end - z) - STEP_FLIGHTS * (STEP_RISERS - 1) * STEP_TREAD) / (STEP_FLIGHTS + 1)
rise = (level(STEPS_ROW, 2) - level(STEPS_ROW + 1, 2)) / (STEP_FLIGHTS * STEP_RISERS)
bed = lambda zz: level(STEPS_ROW, 2) - 1.0 + (level(STEPS_ROW + 1, 2) - level(STEPS_ROW, 2)) * (row_z(STEPS_ROW) - HALF - zz) / (abs(z_end - (row_z(STEPS_ROW) - HALF)))
steps = []
for i in range(STEP_FLIGHTS + 1):
    za, zb = z, z - landing
    steps.append((za, zb, y))
    z = zb
    if i == STEP_FLIGHTS:
        break
    for k in range(STEP_RISERS - 1):
        y -= rise
        steps.append((z, z - STEP_TREAD, y))
        z -= STEP_TREAD
    y -= rise
steps[0] = (steps[0][0] + 1.5, steps[0][1], steps[0][2])
for (za, zb, top) in steps:
    top -= STEP_SINK
    th = top - min(bed(za), bed(zb)) + 1.0
    sx = x - STEP_RUNWAY / 2
    features.append({"type": "ramp", "a": [sx, round(za, 3)], "b": [sx, round(zb, 3)], "lift_a": round(top, 3), "lift_b": round(top, 3),
                     "width": STEP_WIDTH - STEP_RUNWAY, "thickness": round(th, 2), "kind": "#c9c4ba", "plane": "abs"})
rx = x + STEP_WIDTH / 2 - STEP_RUNWAY / 2
features.append({"type": "ramp", "id": "steps_runway", "a": [rx, round(steps[0][0], 3)], "b": [rx, round(z_end, 3)],
                 "lift_a": level(STEPS_ROW, 2) - STEP_SINK, "lift_b": level(STEPS_ROW + 1, 2) - STEP_SINK + 0.1,
                 "width": STEP_RUNWAY, "thickness": 3.0, "kind": "#b0aca3", "plane": "abs"})
hedges = []
for side in (-1, 1):
    zz = row_z(STEPS_ROW) - HALF - 1
    while zz > z_end + 2:
        hedges.append({"p": [side * (STEP_WIDTH / 2 + 0.8), round(zz - 2, 2)], "s": [1.6, 1.3, 3.8], "c": "#3f6b3a"})
        zz -= 4.2
features.append({"type": "solids", "id": "steps_hedges", "style": "prop", "items": hedges})

# --- Parked cars -------------------------------------------------------------------
cars = []


def car(px, pz, yaw):
    col = rng.choice(CAR_COLORS)
    cars.append({"p": [round(px, 2), round(pz, 2)], "s": [1.85, 0.8, 4.4], "yaw": yaw, "lift": 0.18, "c": col})
    cars.append({"p": [round(px, 2), round(pz, 2)], "s": [1.65, 0.62, 2.3], "yaw": yaw, "lift": 0.95, "c": col})


PARK = ROAD / 2 - 1.15
for s in streets:
    sid = s["id"]
    if not (sid.split("_")[-1].isdigit() or sid == "lower_hillcrest"):
        continue
    p0, p3 = s["points"][0], s["points"][-1]
    for side in (-1, 1):
        zz = p0[1] - 16.0   # no parking on the crown or at the crosswalk
        while zz > p3[1] + 6.0:
            px = p0[0] + side * PARK
            if rng.random() < 0.62 and not blocked((px, zz), 3.0) and not (sid == "lower_hillcrest" and side == 1 and zz > -415):
                car(px, zz, 0 if side > 0 else 180)
            zz -= 6.2
for r in range(len(ROWS)):
    for c in range(len(COLS) - 1):
        for side in (-1, 1):
            xx = col_x(c) + HALF + 5.0
            while xx < col_x(c + 1) - HALF - 5.0:
                pz = row_z(r) + side * PARK
                if rng.random() < 0.5 and not blocked((xx, pz), 3.0):
                    car(xx, pz, 90 if side > 0 else -90)
                xx += 6.2
features.append({"type": "solids", "id": "parked_cars", "style": "prop", "items": cars})

# --- Road paint (lane lines and crosswalks only: nothing marks a line) -----------
center_segs = []
zebra = []
for s in streets:
    sid = s["id"]
    pts = s["points"]
    if sid.split("_")[-1].isdigit() or sid in ("lower_hillcrest", "drop_in"):
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            center_segs.append([a[0] - 0.2, a[1], b[0] - 0.2, b[1]])
            center_segs.append([a[0] + 0.2, a[1], b[0] + 0.2, b[1]])
for r in range(len(ROWS)):
    for c in range(len(COLS) - 1):
        xa, xb = col_x(c) + HALF, col_x(c + 1) - HALF
        z = row_z(r)
        center_segs.append([xa, z - 0.2, xb, z - 0.2])
        center_segs.append([xa, z + 0.2, xb, z + 0.2])
    for c in range(len(COLS)):
        x = col_x(c)
        z = row_z(r)
        for zc in (z + HALF - 1.6, z - HALF + 1.6):   # across the downhill street
            for k in range(-5, 6):
                zebra.append([x + k * 1.1, zc + 1.3, x + k * 1.1, zc - 1.3])
features.append({"type": "paint", "id": "centre_lines", "segs": center_segs, "width": 0.14, "c": "#e0b630"})
features.append({"type": "paint", "id": "crosswalks", "segs": zebra, "width": 0.55, "c": "#e9e9e4"})
rails = []
for s in streets:
    if s["id"].startswith("juniper_"):
        for i in range(len(s["points"]) - 1):
            a, b = s["points"][i], s["points"][i + 1]
            for dx in (-0.75, 0.75):
                rails.append([a[0] + dx, a[1], b[0] + dx, b[1]])
for r in range(len(ROWS)):
    for dx in (-0.75, 0.75):
        rails.append([col_x(CABLE_CAR_COL) + dx, row_z(r) + HALF, col_x(CABLE_CAR_COL) + dx, row_z(r) - HALF])
features.append({"type": "paint", "id": "cable_tracks", "segs": rails, "width": 0.12, "c": "#55585c", "lift": 0.035})

# --- Traffic -------------------------------------------------------------------------
for r, (speed, phase) in CROSS_TRAFFIC_ROWS.items():
    z = row_z(r)
    features.append({"type": "traffic", "id": "east_%d" % r, "a": [-262, z + 2.6], "b": [262, z + 2.6], "count": 2,
                     "speed": speed, "phase": phase * speed, "colors": [rng.choice(CAR_COLORS), rng.choice(CAR_COLORS)]})
    features.append({"type": "traffic", "id": "west_%d" % r, "a": [262, z - 2.6], "b": [-262, z - 2.6], "count": 2,
                     "speed": speed * 0.9, "phase": (phase + 11) * speed, "colors": [rng.choice(CAR_COLORS), rng.choice(CAR_COLORS)]})
features.append({"type": "traffic", "id": "bay_east", "a": [-330, PROM_Z + 3.5], "b": [330, PROM_Z + 3.5], "count": 3, "speed": 7.0, "phase": 20})
features.append({"type": "traffic", "id": "bay_west", "a": [330, PROM_Z - 1.5], "b": [-330, PROM_Z - 1.5], "count": 3, "speed": 6.5, "phase": 90})
features.append({"type": "traffic", "id": "cable_car", "style": "cable_car", "a": [col_x(CABLE_CAR_COL), PROM_Z + 4],
                 "b": [col_x(CABLE_CAR_COL), row_z(0)], "count": 3, "speed": 4.2, "phase": 60})

# --- Crowds ----------------------------------------------------------------------------
crowd_id = 0
for r in range(len(ROWS)):
    for c in range(len(COLS)):
        x, z = col_x(c), row_z(r)
        for sx in (-1, 1):
            for sz in (-1, 1):
                if rng.random() < 0.7:
                    cx, cz = x + sx * (HALF - 1.6), z + sz * (HALF - 1.6)
                    features.append({"type": "crowd", "id": "corner_%d" % crowd_id, "a": [cx, cz], "b": [cx + sx * 1.5, cz + sz * 1.5],
                                     "count": rng.randint(1, 4), "spread": 0.7, "seed": crowd_id})
                    crowd_id += 1
        # People crossing the downhill street's crosswalks.
        if (r, c) not in ((TERRACE_ROW, 2), (STEPS_ROW, 2)) and rng.random() < 0.45:
            zc = z - HALF + 1.6
            features.append({"type": "crowd", "id": "crossing_%d" % crowd_id, "a": [x - 6.5, zc], "b": [x + 6.5, zc],
                             "count": 0, "walkers": rng.randint(1, 2), "spread": 0.6, "seed": crowd_id, "walk_speed": 1.3})
            crowd_id += 1
# Sidewalk strollers on the blocks.
for s in streets:
    sid = s["id"]
    if not sid.split("_")[-1].isdigit():
        continue
    p0, p3 = s["points"][0], s["points"][-1]
    for side in (-1, 1):
        if rng.random() < 0.55:
            x = p0[0] + side * SW_OFF
            za = rng.uniform(p3[1] + 10, p0[1] - 10)
            features.append({"type": "crowd", "id": "stroll_%d" % crowd_id, "a": [x, za], "b": [x, za - 12], "count": rng.randint(1, 3),
                             "walkers": rng.randint(0, 1), "spread": 0.8, "seed": crowd_id})
            crowd_id += 1
# Bayfront tourists and the finish-pier crowd.
# Gaps at every street mouth and at the pier so no exit is a wall of people.
_gaps = [col_x(c) for c in range(len(COLS))] + [PIER_X]
_cuts = sorted([g - 11 for g in _gaps] + [g + 11 for g in _gaps])
_spans = [(-325.0, _cuts[0])] + [(_cuts[i], _cuts[i + 1]) for i in range(1, len(_cuts) - 1, 2)] + [(_cuts[-1], 325.0)]
for k, (xa, xb) in enumerate(_spans):
    if xb - xa < 6:
        continue
    n = int((xb - xa) / 4)
    features.append({"type": "crowd", "id": "bayfront_%d" % k, "a": [xa, PROM_Z + 10.5], "b": [xb, PROM_Z + 10.5], "count": n,
                     "walkers": max(1, n // 6), "spread": 1.0, "seed": 900 + k})
    features.append({"type": "crowd", "id": "seawall_%d" % k, "a": [xa, SEAWALL_Z + 1.5], "b": [xb, SEAWALL_Z + 1.5], "count": n // 2,
                     "walkers": max(1, n // 10), "spread": 0.5, "seed": 950 + k})
for side in (-1, 1):
    features.append({"type": "crowd", "id": "pier_fans_%d" % side, "a": [side * (PIER_W / 2 - 0.8), SEAWALL_Z - 6],
                     "b": [side * (PIER_W / 2 - 0.8), PIER_END_Z + 8], "count": 16, "spread": 0.35, "seed": 990 + side})

# --- Seawall, pier and finish -------------------------------------------------------------
seawall = []
for k in range(-33, 33):
    xx = k * 10 + 5
    if abs(xx - PIER_X) < PIER_W / 2 + 1:
        continue
    seawall.append({"p": [xx, SEAWALL_Z + 0.3], "s": [10, 1.1, 0.4], "c": "#8d8a84", "lift": 0.0})
features.append({"type": "solids", "id": "seawall_rail", "style": "prop", "items": seawall})
features.append({"type": "ramp", "id": "pier_deck", "a": [PIER_X, SEAWALL_Z + 1], "b": [PIER_X, PIER_END_Z + 6], "lift_a": PROM_Y,
                 "lift_b": PROM_Y, "width": PIER_W, "thickness": 1.0, "kind": "wood", "plane": "abs"})
features.append({"type": "ramp", "id": "pier_end_lip", "a": [PIER_X, PIER_END_Z + 6], "b": [PIER_X, PIER_END_Z], "lift_a": PROM_Y,
                 "lift_b": PROM_Y + 1.0, "width": PIER_W, "thickness": 1.0, "kind": "wood", "plane": "abs"})
pier_bits = []
zz = SEAWALL_Z - 4
while zz > PIER_END_Z:
    for side in (-1, 1):
        pier_bits.append({"p": [side * (PIER_W / 2 - 0.4), zz], "s": [0.5, 9.5, 0.5], "c": "#5b4636", "top": PROM_Y - 0.9})
    zz -= 9
features.append({"type": "solids", "id": "pier_piles", "style": "building", "items": pier_bits})
pier_rail = []
for side in (-1, 1):
    pier_rail.append({"p": [side * (PIER_W / 2 + 0.1), (SEAWALL_Z + PIER_END_Z) / 2 + 3], "s": [0.2, 0, abs(PIER_END_Z - SEAWALL_Z) - 6], "c": "#6e5a48",
                      "top": PROM_Y + 1.05})
features.append({"type": "solids", "id": "pier_rails", "style": "building", "items": pier_rail})

# --- Landmarks (visual only) -------------------------------------------------------------
features += [
    {"type": "cylinder", "id": "summit_mast", "at": [-34, 66], "radius": 1.4, "top_radius": 0.35, "height": 72, "kind": "#c0392b", "collide": True},
    {"type": "trees", "id": "summit_park", "at": [0, 60], "radius": 26, "count": 14, "seed": 7},
    {"type": "box", "id": "ferry_tower", "at": [-70, -1036], "size": [9, 38, 9], "lift": 8, "kind": "#e6dcc8", "collide": False},
    {"type": "box", "id": "ferry_tower_cap", "at": [-70, -1036], "size": [6, 6, 6], "lift": 46, "kind": "#8a8f96", "collide": False},
    {"type": "box", "id": "ferry_hall", "at": [-70, -1050], "size": [70, 12, 24], "lift": 8, "kind": "#e6dcc8", "collide": False},
    {"type": "box", "id": "bridge_tower_w", "at": [700, -1900], "size": [8, 170, 8], "lift": 0, "kind": "#c0482b", "collide": False},
    {"type": "box", "id": "bridge_tower_e", "at": [1500, -1700], "size": [8, 170, 8], "lift": 0, "kind": "#c0482b", "collide": False},
    {"type": "box", "id": "bridge_deck", "at": [1100, -1800], "heading": 104.0, "size": [12, 4, 1500], "lift": 70, "kind": "#c0482b", "collide": False},
    {"type": "cylinder", "id": "rock_island", "at": [-520, -1900], "radius": 110, "top_radius": 70, "height": 34, "kind": "#6f6c60", "collide": False},
    {"type": "box", "id": "island_block", "at": [-520, -1900], "size": [60, 14, 30], "lift": 34, "kind": "#c9c2b0", "collide": False},
    {"type": "cylinder", "id": "far_hills", "at": [-200, -3800], "radius": 1400, "top_radius": 500, "height": 160, "kind": "#5d7560", "collide": False},
]

# --- Dev autopilot routes ([x, z] or [x, z, cap km/h, jump hold s]) ------------------------
routes["house"] = [[0, 25], [0, -30, 0], [0, -150], [0, -300, 0], [0, -340, 66], [0, -360, 66, 0.5], [0, -380, 0], [0, -420], [0, -480],
                   [0, -560], [0, -598, 40], [0, -650], [0, -700, 0], [0, -800], [0, -920], [0, -1000], [0, -1110]]
routes["runway"] = [[0, -575], [5.25, -590, 0], [5.25, -700], [0, -720], [0, -1000], [0, -1110]]
routes["juniper"] = [[0, 25], [0, -30, 25], [20, -40], [100, -40], [125, -60, 0], [125, -300], [125, -600], [125, -900],
                     [125, -980, 30], [60, -1000], [10, -1012, 0], [0, -1030], [0, -1110]]

level_grid = {
    "xs": [-330, -250, -125, 0, 125, 250, 330],
    "zs": [80, 30] + [r[1] for r in ROWS] + [PROM_Z, SEAWALL_Z, SEAWALL_Z - 8, -1140],
    "ys": [[2, 2, 6, 12, 6, 2, 2], [-3, -4, 0, 9, 0, -4, -4]]
          + [[LEVELS[r][0] + 4] + LEVELS[r] + [LEVELS[r][-1] + 4] for r in range(len(ROWS))]
          + [[PROM_Y] * 7, [PROM_Y] * 7, [-124] * 7, [-124] * 7],
}

data = {
    "name": "Hillcrest Drop",
    "schema_version": 1,
    "design": "design/levels/hillcrest-drop.md",
    "generator": "tools/levels/gen_hillcrest.py",
    "spawn": [0, 26],
    "out_of_bounds_u": 1.0,
    "surfaces": {"grass": {"drag_v2": 0.018, "rolling": 1.0, "min_speed": 4.0},
                 "gravel": {"drag_v2": 0.012, "rolling": 1.0, "min_speed": 4.0}},
    "look": {"terrain": {"concrete_color": "#45474c", "joint_spacing": 1000.0, "edge_color": "#9a978f"}},
    "water": {"y": WATER_Y, "x_min": -3000, "x_max": 3000, "z_from": SEAWALL_Z, "z_to": -4500, "color": "#1f5a73"},
    "terrain": {
        "seed": 31,
        "grid": {"cell": 1.0, "x_min": -330, "x_max": 330, "z_max": 80, "z_min": -1140, "chunk_cells": 64},
        "base": [[80, 0], [-1140, 0]],
        "axis": [[0, 0]],
        "width": [[0, 640]],
        "crown": [[0, 0]],
        "tilt": [[0, 0]],
        "noise": {"large_amp": 0.0, "large_wavelength": 100, "small_amp": 0.15, "small_wavelength": 9},
        "margin": {"wall_deg": 30, "cap": 30, "wander": 0, "wander_wavelength": 100, "rock_above": 3},
        "rock_slope_deg": 52,
        "level_grid": level_grid,
        "streets": streets,
    },
    "gates": [
        {"name": "Pine Terrace", "z": row_z(3), "pads": xs, "pad_offset": 0, "face_down": True,
         "posts": [x + s * (HALF + 0.6) for x in xs for s in (-1, 1)]},
        {"name": "Wharf Hill", "z": row_z(6), "pads": xs, "pad_offset": 0, "face_down": True,
         "posts": [x + s * (HALF + 0.6) for x in xs for s in (-1, 1)]},
        {"name": "Finish", "z": FINISH_Z, "kind": "finish", "arch_x": PIER_X, "y": PROM_Y + (PIER_END_Z + 6 - FINISH_Z) / 6.0,
         "line_width": PIER_W, "arch_width": PIER_W + 1.5},
    ],
    "features": features,
    "routes": routes,
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as f:
    json.dump(data, f, separators=(",", ":"))
n_items = sum(len(ft.get("items", [])) for ft in features)
print("wrote %s: %d streets, %d features, %d merged items, %d sidewalk slabs" % (
    os.path.normpath(OUT), len(streets), len(features), n_items, len(sidewalk_ramps)))
for c in range(len(COLS)):
    grades = []
    for r in range(len(ROWS)):
        y1 = level(r + 1, c) if r + 1 < len(ROWS) else PROM_Y
        z1 = row_z(r + 1) if r + 1 < len(ROWS) else PROM_Z
        grades.append(round(100 * (level(r, c) - y1) / (row_z(r) - z1 - 2 * HALF)))
    print("  %-14s grades %%: %s" % (COLS[c][0], grades))
