#!/usr/bin/env bash
# Clipora for Mac and Linux: run `bash start.sh` (installs everything the first time, then starts the app).
set -e
cd "$(dirname "$0")"
echo; echo "  Clipora - setting up and starting. First time takes 5-15 minutes."; echo

PY=""
for c in python3.12 python3.11 python3.10 python3 python; do
  if command -v $c >/dev/null && $c -c 'import sys; sys.exit(0 if (3,9)<=sys.version_info[:2]<=(3,12) else 1)'; then PY=$c; break; fi
done
if [ -z "$PY" ]; then
  echo "  Python 3.9-3.12 is missing. Mac: brew install python@3.12   Linux: sudo apt install python3 python3-venv"; exit 1
fi
echo "  [1/4] Python ok"

if ! command -v ffprobe >/dev/null; then
  echo "  [2/4] Installing ffmpeg..."
  if command -v brew >/dev/null; then brew install ffmpeg; elif command -v apt >/dev/null; then sudo apt install -y ffmpeg; fi
fi
command -v ffprobe >/dev/null || { echo "  Install ffmpeg (Mac: brew install ffmpeg) and run start.sh again."; exit 1; }
echo "  [2/4] ffmpeg ok"

[ -x .venv/bin/python ] || $PY -m venv .venv
if [ ! -f .venv/installed.txt ]; then
  echo "  [3/4] Installing libraries. This is the long part..."
  .venv/bin/python -m pip install --upgrade pip >/dev/null
  .venv/bin/python -m pip install -r requirements.txt
  .venv/bin/python -m pip install --no-deps -r requirements-translate.txt
  if command -v nvidia-smi >/dev/null; then .venv/bin/python -m pip install -r requirements-gpu.txt; fi
  echo done > .venv/installed.txt
fi
echo "  [3/4] Libraries ok"

mkdir -p workspace
echo "  [4/4] Starting Clipora at http://localhost:8765  (keep this window open; Ctrl+C stops it)"
.venv/bin/python app.py workspace
