#!/usr/bin/env bash
set -e

# ----------------------------------------
# manga2pdf.sh (v1.4)
# Universal manga to PDF converter
# Supports:
# - multi-volume folders
# - nested chapter folders
# - single-folder manga (images in root)
# ----------------------------------------

if [ $# -ne 1 ]; then
  echo "Usage:"
  echo "  $0 /path/to/manga_folder"
  exit 1
fi

SRC_DIR="$1"
SRC_DIR="${SRC_DIR%/}"
DST_DIR="${SRC_DIR}-PDF"

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: source directory does not exist"
  exit 1
fi

mkdir -p "$DST_DIR"

echo "📚 Source directory:"
echo "   $SRC_DIR"
echo "📁 Output directory:"
echo "   $DST_DIR"
echo ""

shopt -s nullglob

# Helper: process one volume
process_volume() {
  local VOLUME_PATH="$1"
  local VOL_NAME="$2"
  local OUT_PDF="$DST_DIR/${VOL_NAME}.pdf"

  echo "➡️ Processing: $VOL_NAME"

  python3 - "$VOLUME_PATH" "$OUT_PDF" <<'PY'
import os, re, sys
from pathlib import Path

try:
    import img2pdf
except Exception:
    print("   ❌ Python module 'img2pdf' not found")
    sys.exit(2)

src = Path(sys.argv[1])
out = Path(sys.argv[2])
img_ext = {".png", ".jpg", ".jpeg"}

def natural_key(s):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", s)]

files = [
    p for p in src.rglob("*")
    if p.is_file() and p.suffix.lower() in img_ext
]

if not files:
    print("   ⚠️ No PNG/JPG images found — skipping")
    sys.exit(0)

files.sort(key=lambda p: natural_key(str(p.relative_to(src))))

print(f"   📄 Pages found: {len(files)}")
print("   ⏳ Creating PDF...")

with open(out, "wb") as f:
    f.write(img2pdf.convert([str(p) for p in files]))

print(f"   ✅ Done: {out.name}")
PY

  echo ""
}

# 🔍 Detect volumes
VOLUMES=("$SRC_DIR"/*/)

ROOT_IMAGES=("$SRC_DIR"/*.png "$SRC_DIR"/*.jpg "$SRC_DIR"/*.jpeg)

if [ ${#VOLUMES[@]} -eq 0 ] && [ ${#ROOT_IMAGES[@]} -ne 0 ]; then
  echo "ℹ️ No subfolders detected — treating as single-volume manga"
  BASENAME=$(basename "$SRC_DIR")
  process_volume "$SRC_DIR" "$BASENAME"
else
  for VOLUME in "${VOLUMES[@]}"; do
    VOL_NAME=$(basename "$VOLUME")
    process_volume "$VOLUME" "$VOL_NAME"
  done
fi

echo "🎉 All volumes processed successfully"
