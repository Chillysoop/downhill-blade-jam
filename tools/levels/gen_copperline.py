#!/usr/bin/env python3
"""Generates assets/data/course_copperline_mountain.json (Copperline Mountain v2,
open form). Design: design/levels/copperline-mountain.md §5.

Usage: python3 tools/levels/gen_copperline.py assets/data/course_copperline_mountain.json

Everything is placed in fan coordinates (u across the fan, -1 west edge .. +1
east edge; z downhill negative) and converted to world X with the same
monotone cubic the game uses (CourseMath.curve), so features stay put when
the meander (axis) or width curves are tuned.
"""
import json
import math
import sys

# ---------------------------------------------------------------- curves
# The whole valley ebbs left and right as it drops (Conner, 2026-11-19), so
# bombing straight down runs into the banks.
AXIS = [[40, 0], [0, 0], [-120, -30], [-330, -230], [-520, -270], [-740, -30],
        [-950, 230], [-1120, 260], [-1320, 60], [-1520, -200], [-1720, -240], [-1900, -220]]
WIDTH = [[40, 140], [0, 150], [-150, 250], [-400, 340], [-700, 400], [-1000, 420],
         [-1300, 440], [-1600, 460], [-1900, 460]]
BASE = [[40, 6], [0, 0], [-150, -34], [-450, -120], [-700, -190], [-1000, -275],
        [-1180, -322], [-1500, -400], [-1840, -480], [-1900, -482]]
FALLS_Z = -1190


def _slope(k, i):
    n = len(k)
    dp = dn = 0.0
    if i > 0:
        dp = (k[i][1] - k[i - 1][1]) / max(k[i - 1][0] - k[i][0], 0.001)
    if i < n - 1:
        dn = (k[i + 1][1] - k[i][1]) / max(k[i][0] - k[i + 1][0], 0.001)
    if i == 0:
        return dn
    if i == n - 1:
        return dp
    if dp * dn <= 0:
        return 0.0
    return 2.0 / (1.0 / dp + 1.0 / dn)


def curve(k, z):
    """Same as CourseMath.curve (monotone cubic over t = -z, clamped)."""
    t = -z
    if t <= -k[0][0]:
        return k[0][1]
    if t >= -k[-1][0]:
        return k[-1][1]
    i = 0
    while i < len(k) - 2 and t > -k[i + 1][0]:
        i += 1
    ta, tb = -k[i][0], -k[i + 1][0]
    va, vb = k[i][1], k[i + 1][1]
    h = tb - ta
    u = (t - ta) / h
    ma, mb = _slope(k, i), _slope(k, i + 1)
    u2, u3 = u * u, u * u * u
    return ((2 * u3 - 3 * u2 + 1) * va + (u3 - 2 * u2 + u) * h * ma
            + (-2 * u3 + 3 * u2) * vb + (u3 - u2) * h * mb)


def X(u, z):
    """World X of across-fan position u at z."""
    return round(curve(AXIS, z) + u * curve(WIDTH, z) * 0.5, 1)


def P(u, z):
    return [X(u, z), z]


def line(us_zs):
    return [P(u, z) for u, z in us_zs]


# Bank the valley into its turns, like a giant berm: where the axis swings
# west going down, the east side is the outside of the turn and sits higher.
TILT = []
for z in range(0, -1900, -100):
    dx = curve(AXIS, z - 60) - curve(AXIS, z + 60)
    TILT.append([z, round(max(-5.0, min(5.0, -dx / 120.0 * 10.0)), 1)])

hard = [[0, 0], [1.5, 12]]
fa = curve(AXIS, FALLS_Z)
fh = curve(WIDTH, FALLS_Z) * 0.5


def zx(u):
    return round(fa + u * fh, 1)


landforms = [
    # A. Crown Slopes (0..-330): rolling ground, a natural halfpipe west, a spine east.
    {"id": "A rollers", "type": "rollers", "z_from": -40, "z_to": -320, "u_from": -0.95, "u_to": 0.95,
     "amp": 0.7, "wavelength": 38, "angle": 15, "fade": 30, "vary": 0.5, "seed": 11},
    {"id": "A tabletop", "type": "hill", "x": X(0.25, -160), "z": -160, "rx": 24, "rz": 55, "height": 3.0, "plateau": 0.4},
    {"id": "A west gully", "type": "ridge", "points": line([(-0.5, -50), (-0.6, -150), (-0.5, -250), (-0.6, -330)]),
     "width": 28, "height": -5.0, "wander": 6},
    {"id": "A east spine", "type": "ridge", "points": line([(0.5, -120), (0.55, -210), (0.45, -300)]),
     "width": 22, "height": 4.0, "plateau": 0.15},
    {"id": "A knob", "type": "hill", "x": X(-0.1, -255), "z": -255, "rx": 16, "rz": 35, "height": 2.0},

    # B. Big Bend (-330..-720): the valley swings west then hard back east.
    {"id": "B centre spine", "type": "ridge", "points": line([(0.05, -380), (0.0, -470), (0.05, -560), (0.0, -650)]),
     "width": 32, "height": 6.0, "plateau": 0.2, "taper": 40},
    {"id": "B west gully", "type": "ridge", "points": line([(-0.55, -350), (-0.6, -480), (-0.5, -600), (-0.55, -710)]),
     "width": 32, "height": -5.0, "wander": 8},
    {"id": "B east gully", "type": "ridge", "points": line([(0.55, -360), (0.6, -470), (0.5, -580), (0.55, -700)]),
     "width": 30, "height": -5.0, "wander": 8},
    {"id": "B pump bowl", "type": "hill", "x": X(-0.3, -440), "z": -440, "rx": 40, "rz": 40, "height": -5.0},
    {"id": "B knuckle rock", "type": "hill", "x": X(0.3, -560), "z": -560, "rx": 12, "rz": 14, "height": 9.0},
    {"id": "B knuckle rock 2", "type": "hill", "x": X(-0.38, -610), "z": -610, "rx": 10, "rz": 12, "height": 8.0},
    {"id": "B rollers", "type": "rollers", "z_from": -600, "z_to": -730, "u_from": -0.95, "u_to": 0.95,
     "amp": 0.9, "wavelength": 45, "angle": -20, "fade": 25, "vary": 0.5, "seed": 12},

    # C. Copper Bowls (-720..-1150): pump through bowls and over tabletops.
    {"id": "C bowl west", "type": "hill", "x": X(-0.4, -800), "z": -800, "rx": 45, "rz": 45, "height": -6.0},
    {"id": "C bowl east", "type": "hill", "x": X(0.35, -905), "z": -905, "rx": 50, "rz": 60, "height": -5.0, "plateau": 0.15},
    {"id": "C bowl low", "type": "hill", "x": X(-0.2, -1020), "z": -1020, "rx": 55, "rz": 60, "height": -5.0, "plateau": 0.25},
    {"id": "C tabletop", "type": "hill", "x": X(0.1, -840), "z": -840, "rx": 26, "rz": 55, "height": 3.0, "plateau": 0.4},
    {"id": "C mesa", "type": "hill", "x": X(-0.5, -950), "z": -950, "rx": 20, "rz": 50, "height": 3.0, "plateau": 0.35},
    {"id": "C hip ridge", "type": "ridge", "points": line([(-0.85, -1060), (-0.1, -1095), (0.6, -1125)]),
     "width": 30, "height": 2.5, "plateau": 0.1},
    {"id": "C rock tor", "type": "hill", "x": X(0.7, -1000), "z": -1000, "rx": 14, "rz": 18, "height": 10.0},

    # E. Meadow Run (-1210..-1840): a snaking natural halfpipe, a spine, tabletops.
    {"id": "E rollers", "type": "rollers", "z_from": -1230, "z_to": -1460, "u_from": -0.95, "u_to": 0.95,
     "amp": 0.8, "wavelength": 42, "angle": 10, "fade": 30, "vary": 0.5, "seed": 13},
    {"id": "E snake gully", "type": "ridge", "points": line([(0.5, -1240), (0.1, -1350), (-0.3, -1450), (-0.1, -1560), (0.25, -1660)]),
     "width": 28, "height": -5.0, "wander": 6},
    {"id": "E west spine", "type": "ridge", "points": line([(-0.5, -1300), (-0.6, -1400), (-0.55, -1500)]),
     "width": 20, "height": 4.0, "plateau": 0.15},
    {"id": "E tabletop", "type": "hill", "x": X(0.45, -1560), "z": -1560, "rx": 22, "rz": 55, "height": 3.0, "plateau": 0.4},
    {"id": "E hump", "type": "hill", "x": X(-0.35, -1620), "z": -1620, "rx": 26, "rz": 45, "height": 2.5},
    {"id": "E rock tor", "type": "hill", "x": X(0.0, -1480), "z": -1480, "rx": 11, "rz": 13, "height": 8.0},
    {"id": "E rollers low", "type": "rollers", "z_from": -1660, "z_to": -1800, "u_from": -0.9, "u_to": 0.9,
     "amp": 0.7, "wavelength": 35, "angle": -10, "fade": 25, "vary": 0.4, "seed": 14},
]

def base_slope(z):
    return (curve(BASE, z + 20) - curve(BASE, z - 20)) / 40.0


# Flow check: a mound whose uphill face is steeper than the slope it sits on
# makes a stopper pocket above it. Obstacles (rock tors, knuckles) are meant to.
for lf in landforms:
    if lf["type"] == "hill":
        face = math.pi * abs(lf["height"]) / (2 * lf.get("rz", lf["rx"]) * (1 - lf.get("plateau", 0)))
        if face > 0.9 * base_slope(lf["z"]) and "rock" not in lf["id"]:
            print("WARNING: %s uphill face %.2f vs slope %.2f" % (lf["id"], face, base_slope(lf["z"])))

d = {
    "name": "Copperline Mountain",
    "schema_version": 1,
    "design": "design/levels/copperline-mountain.md",
    "spawn": [0, -6],
    "out_of_bounds_u": 1.35,
    "surfaces": {
        "grass": {"drag_v2": 0.018, "rolling": 1.0, "min_speed": 4.0},
        "gravel": {"drag_v2": 0.012, "rolling": 1.0, "min_speed": 4.0},
    },
    "terrain": {
        "seed": 2311,
        "grid": {"cell": 2.0, "x_min": -620, "x_max": 620, "z_max": 40, "z_min": -1900, "chunk_cells": 32},
        "base": BASE,
        "axis": AXIS,
        "width": WIDTH,
        "crown": [[0, 2], [-1900, 2]],
        "tilt": TILT,
        "noise": {"large_amp": 3.0, "large_wavelength": 130, "small_amp": 0.5, "small_wavelength": 25},
        "margin": {"wall_deg": 38, "cap": 45, "wander": 20, "wander_wavelength": 180, "rock_above": 4,
                   "bank_width": 35, "bank_height": 10, "bank_surface": "concrete"},
        "rock_slope_deg": 48,
        "fan_surface": "concrete",
        "soft_edges": True,
        "landforms": landforms,
        "rough": [
            {"id": "scrub", "surface": "grass", "z_from": -40, "z_to": -1780, "u_from": -1.0, "u_to": 1.0,
             "wavelength": 70, "threshold": 0.42, "seed": 3},
            {"id": "scree", "surface": "gravel", "z_from": -300, "z_to": -1700, "u_from": -1.0, "u_to": 1.0,
             "wavelength": 40, "threshold": 0.6, "seed": 9},
        ],
        "steps": [
            {"id": "Dry Falls", "z": FALLS_Z, "wave_amp": 8, "wave_length": 160, "extends_down": True, "edge_blend": 60,
             "zones": [
                 {"x_from": zx(-1.5), "x_to": zx(-0.75), "profile": [[0, 0], [70, 12]]},
                 {"x_from": zx(-0.75), "x_to": zx(-0.45), "profile": hard},
                 {"x_from": zx(-0.45), "x_to": zx(-0.3), "profile": [[0, 0], [4, 3], [40, 12]],
                  "surface": "concrete", "surface_from": -2, "surface_to": 40},
                 {"x_from": zx(-0.3), "x_to": zx(0.2), "profile": hard},
                 {"x_from": zx(0.2), "x_to": zx(0.4),
                  "profile": [[0, 0], [3, 1], [9, 4], [16, 4], [19, 5], [25, 8], [32, 8], [35, 9], [41, 12]],
                  "surface": "concrete", "surface_from": -2, "surface_to": 40},
                 {"x_from": zx(0.4), "x_to": zx(0.65), "profile": hard},
                 {"x_from": zx(0.65), "x_to": zx(1.5), "profile": [[0, 0], [50, 12]]},
             ]},
        ],
    },
    "gates": [
        {"name": "Split 1", "z": -560, "pads": [X(-0.55, -575), X(0.55, -575)]},
        {"name": "Split 2", "z": -975, "pads": [X(-0.5, -990), X(0.0, -990), X(0.45, -990)]},
        {"name": "Split 3", "z": -1450, "pads": [X(-0.5, -1465), X(0.3, -1465)]},
        {"name": "Finish", "z": -1840, "kind": "finish", "arch_x": X(0.0, -1840)},
    ],
}

feat = [
    {"id": "start hut", "type": "box", "at": [-16, 10], "size": [6, 3, 5], "kind": "slate"},
    {"id": "start gate L", "type": "box", "at": [-6, -2], "size": [0.4, 3, 0.4], "kind": "green", "collide": False},
    {"id": "start gate R", "type": "box", "at": [6, -2], "size": [0.4, 3, 0.4], "kind": "green", "collide": False},
    {"id": "summit mast", "type": "cylinder", "at": [22, 28], "radius": 0.6, "height": 34, "kind": "metal"},
    # Kit pieces sit where the ground already flows into them.
    {"id": "A table kicker", "type": "kicker", "at": P(0.25, -112), "heading": 0, "width": 10, "length": 5, "height": 1.2},
    {"id": "A spine rail", "type": "rail", "a": P(0.53, -170), "b": P(0.5, -250), "lift": 0.6},
    {"id": "B spine rail", "type": "rail", "a": P(0.02, -480), "b": P(0.04, -550), "lift": 0.6},
    {"id": "C table kicker", "type": "kicker", "at": P(0.1, -806), "heading": 0, "width": 10, "length": 5, "height": 1.2},
    {"id": "E table kicker", "type": "kicker", "at": P(0.45, -1522), "heading": 0, "width": 10, "length": 5, "height": 1.2},
    {"id": "Dry Falls huck lip", "type": "kicker", "at": [zx(-0.375), FALLS_Z + 2], "heading": 0, "width": 30, "length": 2, "height": 0.12},
    # Crash hazards that punish a lazy line.
    {"id": "talus W", "type": "boulders", "at": [zx(-0.6), FALLS_Z - 22], "radius": 22, "count": 26, "seed": 33, "kind": "hazard"},
    {"id": "talus C", "type": "boulders", "at": [zx(-0.05), FALLS_Z - 22], "radius": 40, "count": 46, "seed": 34, "kind": "hazard"},
    {"id": "talus E", "type": "boulders", "at": [zx(0.52), FALLS_Z - 22], "radius": 20, "count": 22, "seed": 35, "kind": "hazard"},
    # Landmarks (scenery, never route markers).
    {"id": "copper headframe", "type": "box", "at": P(-1.1, -830), "size": [7, 40, 7], "lift": 3, "kind": "rust"},
    {"id": "ore ruins", "type": "box", "at": P(-0.75, -760), "size": [10, 4, 8], "kind": "rust"},
    {"id": "needle spire", "type": "cylinder", "at": P(1.12, -640), "radius": 7, "top_radius": 1.2, "height": 36, "kind": "rock"},
    {"id": "chapel", "type": "box", "at": P(0.97, -1400), "size": [8, 8, 12], "kind": "slate"},
    {"id": "chapel spire", "type": "cylinder", "at": P(0.97, -1392), "radius": 2, "top_radius": 0.1, "height": 10, "lift": 8, "kind": "slate", "collide": False},
    {"id": "house 1", "type": "box", "at": P(-1.08, -1790), "size": [14, 7, 12], "kind": "slate"},
    {"id": "house 2", "type": "box", "at": P(1.08, -1800), "size": [12, 6, 14], "kind": "slate"},
    {"id": "margin tree line", "type": "trees", "seed": 5, "margin": {"z_from": 20, "z_to": -1880, "u_from": 1.18, "u_to": 1.32, "spacing": 12}},
    {"id": "chairlift", "type": "chairlift", "points": line([(-1.08, -20), (-1.08, -300), (-1.08, -600), (-1.08, -900), (-1.08, -1150)]),
     "offset": 0, "spacing": 80, "height": 10},
]
d["features"] = feat


def lane(u_by_z, falls_u, cap=None):
    """Bot line through (z, u) samples that crosses Dry Falls at falls_u,
    optionally capping speed (km/h) on the approach to the falls."""
    pts = [[0, -6]]
    done = False
    for z, u in u_by_z:
        if FALLS_Z - 130 <= z <= FALLS_Z + 60:
            if not done:
                pts.append([zx(falls_u), FALLS_Z + 40] + ([cap] if cap else []))
                pts.append([zx(falls_u), FALLS_Z - 30, 0])
                pts.append([X(min(falls_u, 0.75), FALLS_Z - 80), FALLS_Z - 80])
                done = True
            continue
        pts.append(P(u, z))
    pts.append(P(0.0, -1880))
    return pts


def weave(z, phase):
    """Good lines snake across the valley, so none of them is a straight shot."""
    return 0.15 * math.sin(z / 85.0 + phase)


Z = list(range(-40, -1881, -40))
d["routes"] = {
    # Dev autopilot lines (not shown in game). They are the obstacle-free
    # corridors the scatter below keeps open, so at least these lines exist.
    "west": lane([(z, (-0.45 if z > -330 else -0.55) + weave(z, 0.0)) for z in Z], -0.375, 45),
    "east": lane([(z, (0.4 if z > -380 else (0.55 if z > -1040 else 0.72)) + weave(z, 2.0)) for z in Z], 0.85),
    "centre": lane([(z, (0.0 if not (-380 >= z >= -660) else -0.2) + weave(z, 4.0)) for z in Z], 0.3, 40),
    "straight": [[0, -6], [0, -1880]],
}

# ---------------------------------------------------------------- obstacle scatter
# Conner (2026-11-19): "i can just hold forward and finish. that is antithetical
# to the game. Lots of obstacles, lots of turning, lots of finding good lines".
# Trees, boulders and small rock tors are scattered over the whole valley floor
# (and up onto the banks) about SPACING apart, so every few seconds something
# is in your way and you pick a gap. Nothing keeps a straight corridor open:
# the bot lines below are planned through the gaps afterwards, which proves
# a line exists and makes every good line a winding one.
import random

SPACING = 26.0
CLEAR_LINE = 14.0
rng = random.Random(4242)


def seg_dist(px, pz, a, b):
    ax, az = a[0], a[1]
    bx, bz = b[0], b[1]
    dx, dz = bx - ax, bz - az
    l2 = dx * dx + dz * dz
    t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / l2))
    return math.hypot(px - (ax + t * dx), pz - (az + t * dz))


lines = [r for k, r in d["routes"].items() if k != "straight"]
keep_clear = []  # (x, z, radius)
for g in d["gates"]:
    for px in g.get("pads", []):
        keep_clear.append((px, g["z"] - 15, 22))
for f in feat:
    if f["type"] in ("kicker", "rail", "box", "cylinder"):
        a = f.get("at", f.get("a"))
        keep_clear.append((a[0], a[1], 16))
        if "b" in f:
            keep_clear.append((f["b"][0], f["b"][1], 16))
for lf in landforms:
    if lf["type"] == "hill" and "rock" in lf["id"]:
        keep_clear.append((lf["x"], lf["z"], lf["rx"] + 12))


def blocked(x, z):
    u = (x - curve(AXIS, z)) / (curve(WIDTH, z) * 0.5)
    if abs(u) > 1.12 or z > -70 or z < -1800:
        return True
    if FALLS_Z - 80 <= z <= FALLS_Z + 14:   # the cliff band has its own talus
        return True
    for cx, cz, r in keep_clear:
        if math.hypot(x - cx, z - cz) < r:
            return True
    return False


sites = []
cellsz = SPACING / math.sqrt(2)
grid = {}
for _ in range(60000):
    z = rng.uniform(-1800, -70)
    x = rng.uniform(-620, 620)
    gx, gz = int(x // cellsz), int(z // cellsz)
    near = False
    for ix in range(gx - 2, gx + 3):
        for iz in range(gz - 2, gz + 3):
            q = grid.get((ix, iz))
            if q and math.hypot(q[0] - x, q[1] - z) < SPACING:
                near = True
    if near or blocked(x, z):
        continue
    grid[(gx, gz)] = (x, z)
    sites.append((round(x, 1), round(z, 1)))

n_tree = n_boulder = n_tor = 0
obstacles = []  # [x, z, crash radius, feature-or-landform dict, list it lives in]
for lf in landforms:
    if lf["type"] == "hill" and "rock" in lf["id"]:
        obstacles.append([lf["x"], lf["z"], max(lf["rx"], lf.get("rz", lf["rx"])) + 0.5, {}, None])
for f in feat:
    if f["type"] in ("box", "cylinder"):
        r = f.get("radius", max(f.get("size", [1, 1, 1])[0], f.get("size", [1, 1, 1])[2]) * 0.6)
        obstacles.append([f["at"][0], f["at"][1], r + 0.5, {}, None])
    elif f["type"] == "rail":
        for t in (0.0, 0.25, 0.5, 0.75, 1.0):
            obstacles.append([f["a"][0] + (f["b"][0] - f["a"][0]) * t, f["a"][1] + (f["b"][1] - f["a"][1]) * t, 1.5, {}, None])
for i, (x, z) in enumerate(sites):
    roll = rng.random()
    if roll < 0.45:
        n_tree += 1
        feat.append({"id": "scatter tree %d" % i, "type": "trees", "at": [x, z], "radius": 3.5,
                     "count": rng.choice([2, 3, 4]), "seed": 1000 + i})
        obstacles.append([x, z, 4.6, feat[-1], feat])
    elif roll < 0.8:
        n_boulder += 1
        feat.append({"id": "scatter boulders %d" % i, "type": "boulders", "at": [x, z], "radius": 3.0,
                     "count": rng.choice([2, 3, 4]), "size_min": 1.6, "size_max": 3.2, "seed": 2000 + i})
        obstacles.append([x, z, 4.6, feat[-1], feat])
    else:
        n_tor += 1
        landforms.append({"id": "scatter rock %d" % i, "type": "hill", "x": x, "z": z,
                          "rx": round(rng.uniform(5, 8), 1), "rz": round(rng.uniform(5, 8), 1),
                          "yaw": rng.randint(0, 179), "height": round(rng.uniform(4.5, 6.5), 1)})
        lf = landforms[-1]
        obstacles.append([x, z, max(lf["rx"], lf["rz"]) + 0.5, lf, landforms])
print("scatter: %d sites (%d trees, %d boulder groups, %d rock tors)" % (len(sites), n_tree, n_boulder, n_tor))

# ---------------------------------------------------------------- line planning
import heapq

CELL = 4.0
GX0, GX1 = -620.0, 620.0
NXC = int((GX1 - GX0) / CELL) + 1
MARGIN = 6.0      # rider clearance past an obstacle's crash radius (gaps >= 10 m)
SOFT = 4.0        # extra room the planner prefers when it can get it
obs_grid = {}
for k, o in enumerate(obstacles):
    obs_grid.setdefault((int(o[0] // 40), int(o[1] // 40)), []).append(k)


def near_obs(x, z, extra):
    """Index and gap of the obstacle closest to (x, z) within its radius + extra."""
    best = None
    gx, gz = int(x // 40), int(z // 40)
    for ix in (gx - 1, gx, gx + 1):
        for iz in (gz - 1, gz, gz + 1):
            for k in obs_grid.get((ix, iz), []):
                o = obstacles[k]
                if o[2] is None:
                    continue
                gap = math.hypot(o[0] - x, o[1] - z) - o[2]
                if gap < extra and (best is None or gap < best[1]):
                    best = (k, gap)
    return best


def plan(a, b, target_u):
    """A* from a to b (world [x, z]) always moving downhill (at most ~63 deg off
    the fall line, so the line stays rideable at speed), through
    the obstacle field, preferring across-fan position target_u(z)."""
    za = a[1]
    def node(p):
        return (int(round((p[0] - GX0) / CELL)), int(round((za - p[1]) / CELL)))
    def pos(n):
        return (GX0 + n[0] * CELL, za - n[1] * CELL)
    s0, s1 = node(a), node(b)
    openq = [(0.0, 0.0, s0, None)]
    came = {}
    cost = {s0: 0.0}
    while openq:
        f, g, n, prev = heapq.heappop(openq)
        if n in came:
            continue
        came[n] = prev
        if n[1] >= s1[1]:
            break
        for dx, dz, w in ((0, 1, 1.0), (1, 1, 1.414), (-1, 1, 1.414), (2, 1, 2.6), (-2, 1, 2.6)):
            m = (n[0] + dx, n[1] + dz)
            if m[1] > s1[1] or not (0 <= m[0] < NXC):
                continue
            x, z = pos(m)
            u = (x - curve(AXIS, z)) / (curve(WIDTH, z) * 0.5)
            if abs(u) > 1.1:
                continue
            step = CELL * w * (1.0 + 3.0 * (u - target_u(z)) ** 2)
            hit = near_obs(x, z, MARGIN + SOFT)
            if hit:
                step += 400.0 if hit[1] < MARGIN else CELL * 3.0 * (MARGIN + SOFT - hit[1]) / SOFT
            ng = g + step
            if ng < cost.get(m, 1e18):
                cost[m] = ng
                h = abs(m[1] - s1[1]) * CELL + abs(m[0] - s1[0]) * CELL * 0.5
                heapq.heappush(openq, (ng + h, ng, m, n))
    done = [k for k in came if k[1] >= s1[1]]
    if not done:
        raise SystemExit("planner: no way from %s to %s (reached z %.0f)" % (a, b, za - max(k[1] for k in came) * CELL))
    end = min(done, key=lambda k: abs(k[0] - s1[0]))
    path = []
    while end is not None:
        path.append(pos(end))
        end = came[end]
    path.reverse()
    return path


def seg_clear(a, b, room):
    n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 2.0))
    for k in range(n + 1):
        t = k / n
        if near_obs(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, room):
            return False
    return True


def pull_string(path):
    """Straightens a grid path: from each kept point, jump to the farthest
    later point still reachable in a straight line with LINE_ROOM to spare.
    Gives long clean segments a rider (and the bot) can actually hold."""
    out = [path[0]]
    i = 0
    while i < len(path) - 1:
        j = len(path) - 1
        while j > i + 1 and not (seg_clear(path[i], path[j], LINE_ROOM) and abs(path[j][1] - path[i][1]) <= 120):
            j -= 1
        out.append(path[j])
        i = j
    return out


LINE_ROOM = 10.0


def planned_line(lane_pts, target_u):
    """Plans each leg between a lane's anchor points (start, the falls
    approach and exit, finish), clears anything still in the way, and
    thins the path to points every ~20 m."""
    anchors = [lane_pts[0]] + [p for p in lane_pts if p[1] in (FALLS_Z + 40, FALLS_Z - 30, FALLS_Z - 80)] + [lane_pts[-1]]
    anchors = sorted({tuple(p[:2]): p for p in anchors}.values(), key=lambda p: -p[1])
    out = [lane_pts[0]]
    removed = 0
    for a, b in zip(anchors, anchors[1:]):
        in_falls = a[1] <= FALLS_Z + 40 and b[1] >= FALLS_Z - 80
        leg = [(a[0], a[1]), (b[0], b[1])] if in_falls else plan(a, b, target_u)
        for x, z in leg:
            while True:
                hit = near_obs(x, z, MARGIN)
                if not hit:
                    break
                o = obstacles[hit[0]]
                o[3]["removed"] = True
                o[2] = None
                removed += 1
        thin = pull_string(leg) if not in_falls else leg
        for x, z in thin[1:]:
            out.append([round(x, 1), round(z, 1)])
        if len(b) > 2:
            out[-1] = list(b)
    return out, removed


def add_speed_caps(pts):
    """The bot brakes like a rider: before each bend it caps its speed by how
    sharp the bend is (route point [x, z, kmh]; 0 lifts the cap)."""
    out = [list(p[:2]) for p in pts]
    caps = [0] * len(out)
    def heading(a, b):
        return math.atan2(b[0] - a[0], -(b[1] - a[1]))
    for i in range(1, len(out) - 1):
        # Bend over the next ~30 m.
        j = i + 1
        while j < len(out) - 1 and math.hypot(out[j][0] - out[i][0], out[j][1] - out[i][1]) < 30:
            j += 1
        turn = abs(math.degrees(heading(out[i - 1], out[i]) - heading(out[i], out[j])))
        turn = min(turn, 360 - turn)
        cap = 0 if turn < 12 else (58 if turn < 25 else (45 if turn < 45 else 34))
        # Start braking ~25 m before the bend.
        k = i
        while k > 1 and math.hypot(out[k][0] - out[i][0], out[k][1] - out[i][1]) < 25:
            k -= 1
        if cap and (caps[k] == 0 or cap < caps[k]):
            caps[k] = cap
    result = []
    last = None
    for p, c, orig in zip(out, caps, pts):
        if len(orig) > 2:          # keep the falls marks as they are
            result.append(list(orig))
            last = orig[2]
            continue
        want = c
        if want != last:
            result.append(p + [want])
            last = want
        else:
            result.append(p)
    return result


total_removed = 0
for name, lane_u in (("west", lambda z: (-0.45 if z > -330 else -0.55)),
                     ("east", lambda z: (0.4 if z > -380 else (0.55 if z > -1040 else 0.72))),
                     ("centre", lambda z: (0.0 if not (-380 >= z >= -660) else -0.2))):
    line_pts, rm = planned_line(d["routes"][name], lane_u)
    d["routes"][name] = add_speed_caps(line_pts)
    total_removed += rm
for lst in (feat, landforms):
    lst[:] = [f for f in lst if not f.get("removed")]
print("planned 3 lines; cleared %d obstacles that blocked them" % total_removed)

json.dump(d, open(sys.argv[1], "w"), indent=1)
print("wrote", sys.argv[1], "tilt", TILT)
