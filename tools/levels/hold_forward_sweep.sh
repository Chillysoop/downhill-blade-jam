#!/usr/bin/env bash
# Hold-forward sweep for Hillcrest Drop (design/levels/hillcrest-drop.md §13).
# Drops a bot that only holds forward (no steering, no braking) at the top of
# every downhill block, facing straight down, and logs what happens to it in
# its first SECONDS (crowds and traffic removed, so only the streets and
# obstacles can stop it). Observations only: the log says where each run ended and
# why; reading it is the reviewer's job.
#
#   bash tools/levels/hold_forward_sweep.sh <out_dir> [seconds] [jobs]
#
# Needs: godot on PATH or at ~/bin/godot, python3.
set -u
OUT="${1:?out dir}"
SECONDS_RUN="${2:-30}"
JOBS="${3:-3}"
GODOT="$(command -v godot || echo "$HOME/bin/godot")"
cd "$(dirname "$0")/../.."
mkdir -p "$OUT"
python3 - "$OUT/starts.txt" <<'PY'
import json, sys, importlib.util
spec = importlib.util.spec_from_file_location("g", "tools/levels/gen_hillcrest.py")
# The generator runs on import; it rewrites the same deterministic file.
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)
with open(sys.argv[1], "w") as f:
    f.write("summit 0 20\n")
    for r in range(len(g.ROWS)):
        for c in range(len(g.COLS)):
            if (c == 2 and r in (g.TERRACE_ROW, g.STEPS_ROW)):
                continue
            f.write("b%d_%d %.1f %.1f\n" % (r, c, g.bx(r, c), g.row_z(r) - g.HALF - 2))
PY
run_one() {
  name="$1"; x="$2"; z="$3"
  timeout 300 "$GODOT" --headless -- --autopilot=0 --steer=0 --no-people --start-at="$x,$z" --face-down --telemetry --quit-after="$SECONDS_RUN" > "$OUT/$name.log" 2>&1
  first_crash=$(grep -m1 "CRASH" "$OUT/$name.log" | sed 's/^\[t=\([0-9.]*\)\] CRASH: /\1 /')
  minz=$(grep "^t=" "$OUT/$name.log" | sed 's/.*pos=([^,]*,[^,]*,\s*\([-0-9.]*\)).*/\1/' | sort -g | head -1)
  finish=$(grep -m1 "FINISH" "$OUT/$name.log")
  echo "$name start_z=$z lowest_z=${minz:-?} first_crash=${first_crash:-none} ${finish}"
}
export -f run_one; export OUT SECONDS_RUN GODOT
xargs -P "$JOBS" -L1 bash -c 'run_one "$0" "$1" "$2"' < "$OUT/starts.txt" | sort -V > "$OUT/summary.txt"
cat "$OUT/summary.txt"
