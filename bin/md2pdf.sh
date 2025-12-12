#!/usr/bin/env bash
# version 1.3.0
# Sat Nov 22 17:34:49 PST 2025
# md2pdf.sh
# Convert Markdown to PDF with optional letterhead, emoji/Unicode normalization,
# PlantUML diagrams, and XeLaTeX.

set -Eeuo pipefail

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }

# Resolve this script's real directory (follows symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  TARGET="$(readlink "$SOURCE")"
  if [[ "$TARGET" == /* ]]; then
    SOURCE="$TARGET"
  else
    SOURCE="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)/$TARGET"
  fi
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# --- args ------------------------------------------------------------------
if [[ $# -lt 1 || $# -gt 3 ]]; then
  echo "Usage:"
  echo "  $0 <file.md> [out.pdf] [letterhead.md]"
  echo
  echo "Examples:"
  echo "  $0 main.md"
  echo "  $0 main.md out.pdf"
  echo "  $0 main.md letterhead.md"
  echo "  $0 main.md out.pdf letterhead.md"
  exit 1
fi

INPUT="$1"
[[ -f "$INPUT" ]] || die "File not found: $INPUT"
[[ "$INPUT" == *.md || "$INPUT" == *.markdown ]] || die "Input must end with .md or .markdown"
ORIGINAL_INPUT="$INPUT"

OUTPUT=""
LETTERHEAD=""

case $# in
  1)
    OUTPUT="${INPUT%.*}.pdf"
    ;;
  2)
    if [[ "$2" == *.pdf ]]; then
      OUTPUT="$2"
    else
      LETTERHEAD="$2"
      [[ -f "$LETTERHEAD" ]] || die "Letterhead file not found: $LETTERHEAD"
      [[ "$LETTERHEAD" == *.md || "$LETTERHEAD" == *.markdown ]] || die "Letterhead must end with .md or .markdown"
      OUTPUT="${INPUT%.*}.pdf"
    fi
    ;;
  3)
    OUTPUT="$2"
    LETTERHEAD="$3"
    [[ -f "$LETTERHEAD" ]] || die "Letterhead file not found: $LETTERHEAD"
    [[ "$LETTERHEAD" == *.md || "$LETTERHEAD" == *.markdown ]] || die "Letterhead must end with .md or .markdown"
    ;;
esac

[[ -n "${OUTPUT// }" ]] || die "Output path resolved to empty"
mkdir -p "$(dirname "$OUTPUT")"

# --- tools -----------------------------------------------------------------
need=(python3 pandoc xelatex plantuml)
for cmd in "${need[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found in PATH"
done

python3 - <<'PY' || die "pandoc-plantuml-filter not installed (pip install pandoc-plantuml-filter)"
import importlib; importlib.import_module("pandoc_plantuml_filter")
PY

command -v dot >/dev/null 2>&1 || warn "'dot' (Graphviz) not found. Some diagrams may render differently."

# PlantUML behavior
export PLANTUML_BIN="plantuml -failfast2 -charset UTF-8"

# --- config files (kept next to the script) --------------------------------
DEFAULTS="$SCRIPT_DIR/pandoc-pdf.yaml"     # YAML can include header.tex etc.
LUA_FILTER="$SCRIPT_DIR/emoji-textemoji.lua"
FONTS_TEX="$SCRIPT_DIR/fonts.tex"          # optional
HEADER_TEX="$SCRIPT_DIR/header.tex"        # used if no defaults

# --- normalize Unicode punctuation in input --------------------------------
SANITIZED_INPUT="$(mktemp "${TMPDIR:-/tmp}/md2pdf-input-XXXXXX.md")"

python3 - "$INPUT" "$SANITIZED_INPUT" << 'PY'
import sys, pathlib

src_path = pathlib.Path(sys.argv[1])
dst_path = pathlib.Path(sys.argv[2])

text = src_path.read_text(encoding="utf-8")

repl = {
    # hyphens / dashes / minus
    "\u2010": "-",  # hyphen
    "\u2011": "-",  # non breaking hyphen
    "\u2012": "-",  # figure dash
    "\u2013": "-",  # en dash
    "\u2014": "-",  # em dash
    "\u2212": "-",  # minus sign

    # smart single quotes / apostrophes
    "\u2018": "'",  # left single
    "\u2019": "'",  # right single / apostrophe
    "\u201B": "'",  # single high reversed 9

    # smart double quotes
    "\u201C": '"',  # left double
    "\u201D": '"',  # right double
    "\u201F": '"',  # double high reversed 9
}

for k, v in repl.items():
    text = text.replace(k, v)

dst_path.write_text(text, encoding="utf-8")
PY

INPUT="$SANITIZED_INPUT"

# --- resource path ---------------------------------------------------------
INPUT_DIR="$(cd -P "$(dirname "$INPUT")" >/dev/null 2>&1 && pwd)"
RESOURCE_PATH="${INPUT_DIR}:${SCRIPT_DIR}"

LETTERHEAD_DIR=""
if [[ -n "${LETTERHEAD:-}" ]]; then
  LETTERHEAD_DIR="$(cd -P "$(dirname "$LETTERHEAD")" >/dev/null 2>&1 && pwd)"
  if [[ "$LETTERHEAD_DIR" != "$INPUT_DIR" && "$LETTERHEAD_DIR" != "$SCRIPT_DIR" ]]; then
    RESOURCE_PATH="${RESOURCE_PATH}:${LETTERHEAD_DIR}"
  fi
fi

# --- dynamic graphics header for logo next to letterhead -------------------
TMP_GRAPHICS_HEADER=""
if [[ -n "${LETTERHEAD:-}" ]]; then
  [[ -n "$LETTERHEAD_DIR" ]] || LETTERHEAD_DIR="$(cd -P "$(dirname "$LETTERHEAD")" >/dev/null 2>&1 && pwd)"
  TMP_GRAPHICS_HEADER="$(mktemp "${TMPDIR:-/tmp}/md2pdf-graphics-XXXXXX.tex")"
  cat >"$TMP_GRAPHICS_HEADER" <<EOF
% Auto generated, allow images next to letterhead
\graphicspath{{$LETTERHEAD_DIR/}}
EOF
fi

# --- assemble pandoc command ----------------------------------------------
args=()
# disable smart punctuation, allow raw TeX and single backslash math
args+=(-f markdown+raw_tex+tex_math_single_backslash-smart)
args+=(--standalone)
args+=(--pdf-engine=xelatex)
args+=(--resource-path="$RESOURCE_PATH")
args+=(--filter pandoc-plantuml)

# Main document (markdown)
args+=("$INPUT")
args+=(-o "$OUTPUT")

# Inject letterhead LaTeX before body, if provided
if [[ -n "${LETTERHEAD:-}" ]]; then
  args+=(-B "$LETTERHEAD")
fi

# Use defaults if present; otherwise include header.tex directly
if [[ -f "$DEFAULTS" ]]; then
  args+=(--defaults="$DEFAULTS")
else
  warn "Defaults not found: $DEFAULTS (using fallback header includes)"
  [[ -f "$HEADER_TEX" ]] && args+=(--include-in-header="$HEADER_TEX")
fi

# Dynamic graphics path header so LaTeX finds logo next to letterhead
if [[ -n "$TMP_GRAPHICS_HEADER" && -f "$TMP_GRAPHICS_HEADER" ]]; then
  args+=(--include-in-header="$TMP_GRAPHICS_HEADER")
fi

# Lua filter (emoji / Unicode normalization and emojis)
if [[ -f "$LUA_FILTER" ]]; then
  args+=(--lua-filter="$LUA_FILTER")
else
  warn "Lua filter not found: $LUA_FILTER"
fi

# fonts.tex (optional)
[[ -f "$FONTS_TEX" ]] && args+=(--include-in-header="$FONTS_TEX")

# --- run -------------------------------------------------------------------
echo "Converting '$ORIGINAL_INPUT' -> '$OUTPUT'..."
if [[ -n "${LETTERHEAD:-}" ]]; then
  echo "Using letterhead from '$LETTERHEAD'..."
fi

pandoc "${args[@]}"

# cleanup temp files
[[ -n "$TMP_GRAPHICS_HEADER" && -f "$TMP_GRAPHICS_HEADER" ]] && rm -f "$TMP_GRAPHICS_HEADER"
[[ -n "$SANITIZED_INPUT" && -f "$SANITIZED_INPUT" ]] && rm -f "$SANITIZED_INPUT"

echo "✅ Done: $OUTPUT"

