# Quick Design Spec: Fakie, nimbler feet, mph and a carve meter

**Type**: Tweak plus two small features (no new buttons)
**System**: Skater movement (`skate_math.gd`, `skater.gd`, `skater_tuning.gd`), HUD (`hud.gd`, new `carve_meter.gd`), new `carve_guide.gd`
**GDD Reference**: `design/game-brief.md` "Controls — simple and intuitive" (Steer, Push / tuck, Air, Fakie, Speed readout). Rigor is minimal, so the brief is the design record.
**Date**: 2026-11-20

## Change Summary

Conner, 2026-11-20:
1. "skating backwards / landing backwards should work"
2. "still doesn't feel like rollerblading, not as mobile. give me mph instead of kph"
3. "we need onscreen visuals like semi transparent meters somehow indicating turn / carve radius based on speed"

## Rules

**Fakie (real inline: skaters ride and land backwards as easily as forwards).**
- `SkateMath.is_fakie`: you roll toward your heels faster than `fakie_min_speed` (0.5 m/s).
- `judge_landing` measures how far off you are from whichever is nearer, forwards or backwards, and reports `fakie`. A clean 180 lands. Bails still happen between the two, and on hard impacts.
- `landing_heading` straightens a nearly-backwards landing onto exactly backwards.
- Riding fakie: carving works as normal and the turn follows your travel. You can't tuck, and brakes work as normal. The body leans into the turn the right way for facing backwards.
- Press W while fakie and you turn round with a mohawk step (`step_turnaround`). The feet swing through 180° in `turnaround_time` (0.35 s), and the steer at the start picks which way you open up. Speed carries on along your travel; only gravity and air drag act.

**Mobility (nimbler feet).**

| Key | Before | After | Why |
|---|---|---|---|
| `pivot_turn_rate` | 3.0 rad/s | 6.0 | 180 on the spot in about 0.5 s, as quick footwork does |
| `min_turn_radius` | 1.2 m | 0.8 | a jog-pace turn of about 0.8 m with a scissored stance |
| `lean_rate_deg` | 340 | 480 | edge to edge in about 0.2 s |
| `stride_start_share` | (new) 0.25 | | the first push starts a quarter into its stroke, so it bites the moment you press |

Lean (50°) and grip (1.25) are unchanged. They are the physical carve limit, and the meter shows them.

**HUD.**
- Speed now reads in mph (`Hud.format_speed`, m/s × 2.2369).
- `CarveMeter` sits at the bottom centre, see-through. It is a half dial whose needle is your lean. A red band shows where the wheels' grip runs out at your current speed (`grip_edge = atan(grip(v)) / lean_limit`). Below it reads "turn N m · tightest N m" (`SkateMath.tightest_radius` = the wider of the full-lean radius and the grip radius).
- `CarveGuide` draws faint painted lines on the ground: the tightest carve left and right at your speed, plus your current arc in green (red when the wheels slide). Their widths come from data (`arc_length`, `limit_alpha`, `current_alpha`, `line_width`).

## Acceptance Criteria

- [x] Unit tests for fakie landing and alignment, `is_fakie`, turnaround timing and side, tightest radius vs speed and tuck, slow footwork, the instant first push, mph and the meter math. All were red before the change.
- [x] Integration `test_skater_fakie.gd`: a 1.5 m drop landed backwards at 8 m/s rolls away fakie, and W turns you round in under 0.5 s keeping your speed. Against the old code it fails 5 checks.
- [x] Screenshots: the carve meter and ground lines while carving; riding fakie.
- [x] Every bot route that finished before still finishes.
- [ ] Conner confirms it feels mobile and the meter helps (playtest).
