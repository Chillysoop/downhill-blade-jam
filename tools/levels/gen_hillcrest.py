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

# The whole hill ebbs left and right (Conner, 2026-11-19: "the entire map can
# ebb left and right, so you can't just bomb straight down"): a slow sideways
# lean that swaps sides down the hill, so the fall line wanders across the grid
# and the fastest street changes from block to block. Every street still drops
# at least MIN_BLOCK_DROP per block (no uphill blocks, no dead ends).
EBB_AMP = 7.0            # metres of extra height at the grid edge (x = ±250)
EBB_WAVELENGTH = 520.0   # metres down the hill for one full left-right-left swing
EBB_PHASE = 0.6          # radians
MIN_BLOCK_DROP = 4.0
_raw_levels = [row[:] for row in LEVELS]
for _r in range(len(LEVELS)):
    _z = -40.0 - 110.0 * _r
    for _c, _x in enumerate([-250.0, -125.0, 0.0, 125.0, 250.0]):
        LEVELS[_r][_c] = round(_raw_levels[_r][_c] + EBB_AMP * math.sin(2 * math.pi * -_z / EBB_WAVELENGTH + EBB_PHASE) * _x / 250.0, 1)
for _c in range(5):
    for _r in range(1, len(LEVELS)):
        LEVELS[_r][_c] = min(LEVELS[_r][_c], LEVELS[_r - 1][_c] - MIN_BLOCK_DROP)
    LEVELS[-1][_c] = max(LEVELS[-1][_c], -112.0 + 3.0)

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

# --- Obstacles (hold-forward pass, 2026-11-19) -----------------------------------
FIELD_EDGE = 9.0        # open-block fields stay this far inside the block (streets stay clear)
FIELD_PITCH = 10.0      # prop spacing across the slope
FIELD_PROP_W = 5.0      # prop width: half the pitch, so two staggered rows leave no straight gap
FIELD_ROW_GAP = 13.0    # rows down the slope
FIELD_LOW_SHARE = 0.3   # share of props low enough to hop (about 0.5 m) instead of weave round
WORKS_W = 6.5           # street works: barricade width across the road
WORKS_L = 8.0           # and length along it
WORKS_OFFSET = 2.4      # centre this far off the crown, so it covers the middle of the road
works_zones = []        # (x, z) of each dig: parked cars keep clear
CURB_CUT = 4.0          # corners are flush this far along the cross street: you can cut a jog tight without tripping on a curb

# --- Traffic and crowds ---------------------------------------------------------
CROSS_TRAFFIC_ROWS = {1: (8.5, 0.0), 4: (9.0, 3.0), 6: (8.0, 7.0), 8: (9.5, 1.5)}  # row: (speed, phase)
CABLE_CAR_COL = 3
SEED = 4242

# --- Open blocks (open-form pass, Conner 2026-11-19: "way more fluid and open
# form", big open maps but bounded and downhill). A checkerboard of blocks has
# no buildings: the whole block is a paved, sloping hillside you can carve
# across from any street, dressed as a park, plaza or parking lot. Diagonal
# neighbours touch at intersections, so open blocks chain into free lines
# from the summit to the bay.
OPEN_KINDS = ["park", "plaza", "parking"]


# --- Jogged grid (Conner 2026-11-19: "i can just hold forward and finish. that is
# antithetical to the game. Lots of obstacles, lots of turning, lots of finding
# good lines"). Like the offset intersections of real hill towns, every
# downhill street steps sideways at each cross street, alternating left and
# right, so riding straight across an intersection runs you into the
# buildings on the far side. To keep going you turn onto the cross street and
# turn down again, or cut a diagonal through an open block or an alley.
# Only the House Jump stays straight: Sacra -> Pine Terrace -> the house is the
# one long run-up, and you have to reach it first.
JOG = 16.0                           # each street sits this far left or right of its column line
STRAIGHT_BLOCKS = {(2, 2), (3, 2)}   # (block row, column) kept on the line: the House Jump run-up
IX_HALF = JOG + HALF                 # half-length of an intersection along its cross street (covers both mouths)
X_EDGE = 292.0                       # cross streets run out to here either side


def is_open(r, c):
    """Block between rows r..r+1 and columns c..c+1 (r may be 8: Shore to Bayfront)."""
    return (r + c) % 2 == 0

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


def block_off(r, c):
    """Sideways jog of column c's street on block row r (row r down to row r + 1)."""
    if (r, c) in STRAIGHT_BLOCKS:
        return 0.0
    return JOG if (r + c) % 2 == 0 else -JOG


def bx(r, c):
    """Centre x of column c's downhill street on block row r. Block rows run 0..8
    (8 = Shore St down to the Bayfront); -1 is the drop-in above Crest Way."""
    if r < 0:
        return 0.0 if c == 2 else col_x(c)
    return col_x(c) + block_off(r, c)


def node(r, c):
    return (col_x(c), row_z(r), level(r, c))


def cross_y(r, x):
    """Height of cross street r at x (level within intersections, linear between)."""
    xs = [col_x(c) for c in range(len(COLS))]
    for c in range(len(xs)):
        if abs(x - xs[c]) <= IX_HALF:
            return level(r, c)
    if x < xs[0]:
        return level(r, 0)
    if x > xs[-1]:
        return level(r, len(xs) - 1)
    for c in range(len(xs) - 1):
        a = xs[c] + IX_HALF
        b = xs[c + 1] - IX_HALF
        if a <= x <= b:
            t = (x - a) / (b - a)
            return level(r, c) + t * (level(r, c + 1) - level(r, c))
    return level(r, 0)


def block_profile(c, r):
    """Points [x, z, y] down column c from row r's downhill edge to the next row's uphill edge."""
    x = bx(r, c)
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
        x = bx(r, c)
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
    pts = [[-X_EDGE, row_z(r), level(r, 0)]]
    for c in range(len(COLS)):
        pts.append([col_x(c) - IX_HALF, row_z(r), level(r, c)])
        pts.append([col_x(c) + IX_HALF, row_z(r), level(r, c)])
    pts.append([X_EDGE, row_z(r), level(r, len(COLS) - 1)])
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
        names = [cc[0].split()[0].lower() for cc in COLS]
        col = names.index(sid.split("_")[0]) if is_block else 2
        brow = int(sid.split("_")[-1]) if is_block else (TERRACE_ROW if sid == "lower_hillcrest" else -1)
        for side in (-1, 1):
            gap = col - 1 if side < 0 else col
            if brow >= 0 and 0 <= gap < len(COLS) - 1 and is_open(brow, gap):
                continue   # flush edge: roll straight off the street into the open block
            for i in range(len(pts) - 1):
                a, b = pts[i], pts[i + 1]
                add_sidewalk((a[0] + side * SW_OFF, a[1]), (b[0] + side * SW_OFF, b[1]), a[2], b[2])
    elif is_cross:
        r = [i for i, rr in enumerate(ROWS) if rr[0].lower().replace(" ", "_") == sid][0]
        for side in (-1, 1):
            z = pts[0][1] + side * SW_OFF
            brow = r if side < 0 else r - 1   # the block row this side of the street faces
            if brow < 0:   # north side of Crest Way: one mouth, the drop-in
                for xa, xb in ((-X_EDGE + 20, -HALF), (HALF, X_EDGE - 20)):
                    add_sidewalk((xa, z), (xb, z), cross_y(r, xa), cross_y(r, xb))
                continue
            for c in range(len(COLS) - 1):
                if is_open(brow, c):
                    continue
                xa = bx(brow, c) + HALF + CURB_CUT
                xb = bx(brow, c + 1) - HALF - CURB_CUT
                add_sidewalk((xa, z), (xb, z), cross_y(r, xa), cross_y(r, xb))
# Promenade: inland sidewalk only, open at every street mouth; the seaward
# edge is the seawall rail.
_edges = [-330.0] + [v for c in range(len(COLS)) for v in (bx(8, c) - HALF, bx(8, c) + HALF)] + [330.0]
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


cars = []


def car(px, pz, yaw):
    col = rng.choice(CAR_COLORS)
    cars.append({"p": [round(px, 2), round(pz, 2)], "s": [1.85, 0.8, 4.4], "yaw": yaw, "lift": 0.18, "c": col})
    cars.append({"p": [round(px, 2), round(pz, 2)], "s": [1.65, 0.62, 2.3], "yaw": yaw, "lift": 0.95, "c": col})


DEPTH = 16.0
open_blocks = []
xs = [col_x(c) for c in range(len(COLS))]
row_edges = [row_z(r) for r in range(len(ROWS))] + [PROM_Z]
for r in range(len(ROWS)):
    z_top = row_z(r) - HALF
    z_bot = (row_z(r + 1) + HALF) if r + 1 < len(ROWS) else PROM_Z + PROM_W / 2
    for c in range(len(COLS) - 1):
        xa = bx(r, c) + HALF
        xb = bx(r, c + 1) - HALF
        tall = (c <= 1 and r >= 6)
        if is_open(r, c):
            open_blocks.append((r, c, xa, xb, z_top, z_bot))
            continue
        # Frontages on the two downhill streets (full block length).
        lot_row(xa, xa, z_top, z_bot, False, +1, DEPTH, tall)
        lot_row(xb, xb, z_top, z_bot, False, -1, DEPTH, tall)
        # Frontages on the two cross streets (between the side rows).
        lot_row(xa + DEPTH, xb - DEPTH, z_top, z_top, True, -1, DEPTH, tall)
        lot_row(xa + DEPTH, xb - DEPTH, z_bot, z_bot, True, +1, DEPTH, tall)
    # Outer edges of the grid.
    lot_row(bx(r, 0) - HALF, bx(r, 0) - HALF, z_top, z_bot, False, -1, 40.0, r >= 6)
    lot_row(bx(r, len(COLS) - 1) + HALF, bx(r, len(COLS) - 1) + HALF, z_top, z_bot, False, +1, 40.0, False)
# North side of Crest Way, either side of the summit park.
for xa, xb in ((-300.0, -40.0), (40.0, 300.0)):
    lot_row(xa, xb, row_z(0) + HALF, row_z(0) + HALF, True, +1, DEPTH)
# Hillcrest Ave above Crest Way (the drop-in) is lined with houses too.
lot_row(-HALF, -HALF, 14.0, row_z(0) + HALF + DEPTH, False, -1, DEPTH)
lot_row(HALF, HALF, 14.0, row_z(0) + HALF + DEPTH, False, +1, DEPTH)

houses.append(dict(HOUSE))   # the jump house, roof below the terrace

# Dress the open blocks. Their ground is the smooth lot plane between the four
# intersections, painted concrete; what sits on it is sparse so lines stay free.
bands = []
landforms = []   # park mounds and plaza bowls (open-form stamps, docs/course-data-schema.md)
open_props = []
for k, (r, c, xa, xb, z_top, z_bot) in enumerate(open_blocks):
    kind = OPEN_KINDS[k % len(OPEN_KINDS)]
    cx = (xa + xb) / 2
    w = xb - xa
    bands.append({"id": "open_%d_%d" % (r, c), "points": [[cx, z_top + 4], [cx, (z_top + z_bot) / 2], [cx, z_bot - 4]],
                  "width": w + 8, "surface": "concrete", "paint_frac": 1.0, "keep": ["rock"]})
    L = z_top - z_bot
    # Something to carve or pump in every open block, well clear of the streets.
    if kind == "park":
        for m in range(2):
            mx = xa + w * (0.3 + 0.4 * m) + rng.uniform(-6, 6)
            mz = z_top - L * (0.3 + 0.4 * ((m + k) % 2)) + rng.uniform(-6, 6)
            landforms.append({"type": "hill", "x": round(mx, 1), "z": round(mz, 1), "rx": round(rng.uniform(11, 16), 1),
                              "rz": round(rng.uniform(13, 20), 1), "yaw": rng.randint(0, 180), "height": round(rng.uniform(1.6, 3.0), 1)})
    elif kind == "plaza":
        landforms.append({"type": "hill", "x": round(cx, 1), "z": round(z_top - L * 0.7, 1), "rx": 16.0, "rz": 14.0,
                          "height": -2.4, "plateau": 0.35})
    if kind == "park":
        for t in range(rng.randint(3, 5)):
            px = rng.uniform(xa + 12, xb - 12)
            pz = rng.uniform(z_bot + 12, z_top - 12)
            if blocked((px, pz), 8):
                continue
            features.append({"type": "trees", "id": "park_%d_%d_%d" % (r, c, t), "at": [round(px, 1), round(pz, 1)],
                             "radius": rng.uniform(4, 9), "count": rng.randint(2, 5), "seed": 300 + k * 10 + t})
    elif kind == "plaza":
        fx, fz = cx + rng.uniform(-15, 15), (z_top + z_bot) / 2 + rng.uniform(-12, 12)
        features.append({"type": "cylinder", "id": "fountain_%d_%d" % (r, c), "at": [round(fx, 1), round(fz, 1)],
                         "radius": 4.5, "height": 1.1, "kind": "#b9b5ad", "collide": True})
        features.append({"type": "crowd", "id": "plaza_%d_%d" % (r, c), "a": [round(fx - 12, 1), round(fz + 9, 1)],
                         "b": [round(fx + 12, 1), round(fz + 9, 1)], "count": 6, "walkers": 3, "spread": 3.0, "seed": 400 + k})
        for b in range(4):
            bnx = rng.uniform(xa + 8, xb - 8)
            bz = rng.uniform(z_bot + 8, z_top - 8)
            if not blocked((bnx, bz), 3):
                open_props.append({"p": [round(bnx, 1), round(bz, 1)], "s": [2.2, 0.5, 0.7], "yaw": rng.choice([0, 90]), "lift": 0.0, "c": "#7a5c44"})
    else:  # parking lot: bays run downhill with wide aisles, so you flow down them
        for col_k in range(3):
            px = xa + w * (0.25 + 0.25 * col_k)
            pz = z_top - 10
            while pz > z_bot + 10:
                if rng.random() < 0.55 and not blocked((px, pz), 3.5):
                    car(px, pz, rng.choice([90, -90]))
                pz -= 3.0
# Obstacle fields: every open block is a slalom. Staggered rows of props
# (hedges and boulders in parks, planters and benches on plazas, kerbed islands
# and cars in parking lots) with gaps narrower than the props, offset row to
# row, so no straight line crosses a block: you weave, or hop the low ones.
for k, (r, c, xa, xb, z_top, z_bot) in enumerate(open_blocks):
    kind = OPEN_KINDS[k % len(OPEN_KINDS)]
    fr = random.Random(SEED * 7 + k)
    zz = z_top - FIELD_EDGE
    row_i = 0
    while zz > z_bot + FIELD_EDGE:
        x = xa + FIELD_EDGE + (FIELD_PITCH / 2 if row_i % 2 else 0.0) + fr.uniform(-1.5, 1.5)
        while x < xb - FIELD_EDGE:
            low = fr.random() < FIELD_LOW_SHARE
            if kind == "park":
                item = {"s": [FIELD_PROP_W, 0.55 if low else 1.4, 2.0], "c": "#7d7a70" if low else "#3f6b3a"}
            elif kind == "plaza":
                item = {"s": [FIELD_PROP_W, 0.5 if low else 0.95, 1.6], "c": "#7a5c44" if low else "#a8a196"}
            else:
                item = {"s": [FIELD_PROP_W, 0.25 if low else 0.9, 2.4], "c": "#b9b5ad" if low else rng.choice(CAR_COLORS)}
            pz = zz + fr.uniform(-1.5, 1.5)
            if not blocked((x, pz), FIELD_PROP_W / 2 + 2.0):
                item.update({"p": [round(x, 1), round(pz, 1)], "yaw": fr.choice([0, 0, 15, -15]), "lift": 0.0})
                open_props.append(item)
            x += FIELD_PITCH
        zz -= FIELD_ROW_GAP
        row_i += 1
features.append({"type": "solids", "id": "open_block_props", "style": "prop", "items": open_props})

# Street works: one per closed block, a barricaded dig that takes most of the
# road on one side (alternating) so even the streets make you steer.
works = []
for s_ in streets:
    sid = s_["id"]
    if not sid.split("_")[-1].isdigit() or sid.startswith(("lantern", "mint", "fog", "cannery", "rope", "tar")):
        continue
    names = [cc[0].split()[0].lower() for cc in COLS]
    if sid.split("_")[0] not in names:
        continue
    wc = names.index(sid.split("_")[0])
    wr = int(sid.split("_")[-1])
    if (wr, wc) in STRAIGHT_BLOCKS:
        continue
    p0, p3 = s_["points"][0], s_["points"][-1]
    side = 1 if (wr * 3 + wc) % 2 else -1
    wz = p0[1] + (p3[1] - p0[1]) * rng.uniform(0.3, 0.5)
    wx = p0[0] + side * WORKS_OFFSET
    works.append({"p": [round(wx, 2), round(wz, 2)], "s": [WORKS_W, 1.05, WORKS_L], "c": "#d9822b", "lift": 0.0})
    works_zones.append((wx, wz))
features.append({"type": "solids", "id": "street_works", "style": "prop", "items": works})
features.append({"type": "solids", "id": "houses", "style": "building", "items": houses})
features.append({"type": "solids", "id": "downtown", "style": "building", "items": downtown})

# --- The House Jump driveway (plain concrete, unmarked) --------------------------
features.append({"type": "kicker", "id": "terrace_driveway", "at": DRIVEWAY["at"], "heading": 0,
                 "length": DRIVEWAY["length"], "height": DRIVEWAY["height"], "width": DRIVEWAY["width"], "kind": "#b9b5ad"})

# --- Hillcrest Steps ---------------------------------------------------------------
x = bx(STEPS_ROW, 2)
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
        hedges.append({"p": [x + side * (STEP_WIDTH / 2 + 0.8), round(zz - 2, 2)], "s": [1.6, 1.3, 3.8], "c": "#3f6b3a"})
        zz -= 4.2
features.append({"type": "solids", "id": "steps_hedges", "style": "prop", "items": hedges})

# --- Parked cars -------------------------------------------------------------------
PARK = ROAD / 2 - 1.15
for s in streets:
    sid = s["id"]
    if not (sid.split("_")[-1].isdigit() or sid == "lower_hillcrest"):
        continue
    p0, p3 = s["points"][0], s["points"][-1]
    names = [cc[0].split()[0].lower() for cc in COLS]
    pcol = names.index(sid.split("_")[0]) if sid != "lower_hillcrest" else 2
    prow = int(sid.split("_")[-1]) if sid != "lower_hillcrest" else TERRACE_ROW
    for side in (-1, 1):
        gap = pcol - 1 if side < 0 else pcol
        if 0 <= gap < len(COLS) - 1 and is_open(prow, gap):
            continue   # nothing parked along an open block's edge
        zz = p0[1] - 16.0   # no parking on the crown or at the crosswalk
        while zz > p3[1] + 6.0:
            px = p0[0] + side * PARK
            if rng.random() < 0.62 and not blocked((px, zz), 3.0) and not any(abs(px - wx) < 9 and abs(zz - wz) < 17 for wx, wz in works_zones) and not (sid == "lower_hillcrest" and side == 1 and zz > -415):
                car(px, zz, 0 if side > 0 else 180)
            zz -= 6.2
for r in range(len(ROWS)):
    for c in range(len(COLS) - 1):
        for side in (-1, 1):
            brow = r if side < 0 else r - 1
            if brow >= 0 and is_open(brow, c):
                continue
            xx = col_x(c) + IX_HALF + 4.0   # never inside an intersection: the jog needs the whole street
            while xx < col_x(c + 1) - IX_HALF - 4.0:
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
    z = row_z(r)
    center_segs.append([-X_EDGE, z - 0.2, X_EDGE, z - 0.2])
    center_segs.append([-X_EDGE, z + 0.2, X_EDGE, z + 0.2])
    for c in range(len(COLS)):
        for x, zc in ((bx(r - 1, c), z + HALF - 1.6), (bx(r, c), z - HALF + 1.6)):   # across each mouth
            if r == 0 and zc > z and c != 2:
                continue
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
for r in range(1, len(ROWS)):   # the jog across each intersection
    for dx in (-0.75, 0.75):
        rails.append([bx(r - 1, CABLE_CAR_COL) + dx, row_z(r) + HALF, bx(r, CABLE_CAR_COL) + dx, row_z(r) - HALF])
features.append({"type": "paint", "id": "cable_tracks", "segs": rails, "width": 0.12, "c": "#55585c", "lift": 0.035})

# --- Traffic -------------------------------------------------------------------------
for r, (speed, phase) in CROSS_TRAFFIC_ROWS.items():
    z = row_z(r)
    features.append({"type": "traffic", "id": "east_%d" % r, "a": [-X_EDGE, z + 2.6], "b": [X_EDGE, z + 2.6], "count": 2,
                     "speed": speed, "phase": phase * speed, "colors": [rng.choice(CAR_COLORS), rng.choice(CAR_COLORS)]})
    features.append({"type": "traffic", "id": "west_%d" % r, "a": [X_EDGE, z - 2.6], "b": [-X_EDGE, z - 2.6], "count": 2,
                     "speed": speed * 0.9, "phase": (phase + 11) * speed, "colors": [rng.choice(CAR_COLORS), rng.choice(CAR_COLORS)]})
features.append({"type": "traffic", "id": "bay_east", "a": [-330, PROM_Z + 3.5], "b": [330, PROM_Z + 3.5], "count": 3, "speed": 7.0, "phase": 20})
features.append({"type": "traffic", "id": "bay_west", "a": [330, PROM_Z - 1.5], "b": [-330, PROM_Z - 1.5], "count": 3, "speed": 6.5, "phase": 90})
# The cable car climbs Juniper one block at a time (the line jogs with the street).
for r in range(0, len(ROWS), 2):
    x = bx(r, CABLE_CAR_COL)
    z_lo = (row_z(r + 1) + HALF) if r + 1 < len(ROWS) else PROM_Z + PROM_W / 2
    features.append({"type": "traffic", "id": "cable_car_%d" % r, "style": "cable_car", "a": [x - 0.0, z_lo + 6],
                     "b": [x, row_z(r) - HALF - 6], "count": 1, "speed": 4.2, "phase": 13.0 * r})

# --- Crowds ----------------------------------------------------------------------------
crowd_id = 0
for r in range(len(ROWS)):
    for c in range(len(COLS)):
        z = row_z(r)
        x = bx(r, c)
        for sx in (-1, 1):
            for sz in (-1, 1):
                if rng.random() < 0.7:
                    xm = bx(r - 1, c) if sz > 0 else bx(r, c)   # corners of the mouth on that side
                    cx, cz = xm + sx * (HALF - 1.6), z + sz * (HALF - 1.6)
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
_gaps = [bx(8, c) for c in range(len(COLS))] + [PIER_X]
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
JOG_CAP = 24.0   # km/h the route bots slow to before an offset intersection


def street_route(cols, house=False, steps_runway=True):
    """Autopilot route down the jogged grid: cols[r] is the column taken on block
    row r (0..8). Slows for every jog, steers round street works, takes the
    steps runway on Hillcrest. house=True pops the driveway over the jump house."""
    pts = [[0, 25], [0, 0]]
    prev_x = 0.0
    for r in range(len(ROWS)):
        c = cols[r]
        x = bx(r, c)
        z = row_z(r)
        if house and r == TERRACE_ROW:
            pts += [[x, z + HALF + 25, 66], [x, -360, 66, 0.5], [x, -380, 0], [x, -420]]
            prev_x = x
            continue
        steps = c == 2 and r == STEPS_ROW and steps_runway
        if steps:   # aim for the smooth runway beside the stairs
            x = x + STEP_WIDTH / 2 - STEP_RUNWAY / 2
        cap_z = min(z + HALF + 30, pts[-1][1] - 2)   # brake early: arriving fast at a jog is a bail
        pts.append([prev_x, cap_z, JOG_CAP])
        if cap_z - 2 > z + HALF + 6:
            pts.append([prev_x, z + HALF + 6])
        if abs(x - prev_x) > 2 * IX_HALF:   # changing column: ride the cross street
            pts += [[prev_x + math.copysign(10, x - prev_x), z - 1.5], [x - math.copysign(14, x - prev_x), z - 2.5]]
        elif steps:   # square up on the cross street: the runway is narrow
            pts += [[prev_x + 0.6 * (x - prev_x), z + 1.5], [x, z - 3]]
        elif abs(x - prev_x) > 1:
            dx = x - prev_x
            pts += [[prev_x + 0.35 * dx, z + 1.5], [x - 0.1 * dx, z - HALF + 1]]
        if steps:
            pts += [[x, z - HALF - 8, 40], [x, row_z(r + 1) + HALF + 2, 0]]
        else:
            pts.append([x, z - HALF - 8, 0])
        for wx, wz in works_zones:
            if abs(wx - x) < 6 and (row_z(r + 1) if r + 1 < len(ROWS) else PROM_Z) < wz < z:
                side = 1 if wx > x else -1
                pts += [[x - side * 3.4, wz + 12], [x - side * 3.4, wz - 7]]
        prev_x = x
    pts += [[prev_x, min(PROM_Z + PROM_W / 2 + 30, pts[-1][1] - 2), JOG_CAP], [(prev_x + PIER_X) / 2, PROM_Z], [PIER_X, SEAWALL_Z - 3, 0], [PIER_X, -1110]]
    return pts


routes["house"] = street_route([2, 2, 2, 2, 2, 2, 2, 2, 2], house=True)
routes["hillcrest"] = street_route([2, 2, 2, 3, 2, 2, 2, 2, 2])
routes["juniper"] = street_route([3, 3, 3, 3, 3, 3, 3, 3, 3])
routes["quarry"] = street_route([0, 0, 0, 0, 0, 0, 0, 0, 0])

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
        "bands": bands,
        "landforms": landforms,
    },
    "gates": [
        {"name": "Pine Terrace", "z": row_z(3), "pads": [bx(3, c) for c in range(len(COLS))], "pad_offset": 0, "face_down": True,
         "posts": [bx(3, c) + s * (HALF + 0.6) for c in range(len(COLS)) for s in (-1, 1)]},
        {"name": "Wharf Hill", "z": row_z(6), "pads": [bx(6, c) for c in range(len(COLS))], "pad_offset": 0, "face_down": True,
         "posts": [bx(6, c) + s * (HALF + 0.6) for c in range(len(COLS)) for s in (-1, 1)]},
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
