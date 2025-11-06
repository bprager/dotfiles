#!/usr/bin/env bash
# version 1.1.1
# Thu Nov  6 13:55:00 PST 2025
set -Eeuo pipefail

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }

# Resolve this script's real directory (follows symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  TARGET="$(readlink "$SOURCE")"
  if [[ "$TARGET" == /* ]]; then SOURCE="$TARGET"
  else SOURCE="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)/$TARGET"
  fi
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# --- args ------------------------------------------------------------------
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <file.md> [out.pdf]"
  exit 1
fi
INPUT="$1"
[[ -f "$INPUT" ]] || die "File not found: $INPUT"
[[ "$INPUT" == *.md || "$INPUT" == *.markdown ]] || die "Input must end with .md or .markdown"

if [[ $# -eq 2 ]]; then
  OUTPUT="$2"
else
  OUTPUT="${INPUT%.*}.pdf"
fi
[[ -n "${OUTPUT// }" ]] || die "Output path resolved to empty"
mkdir -p "$(dirname "$OUTPUT")"

# --- tools -----------------------------------------------------------------
need=(python3 pandoc xelatex plantuml)
for cmd in "${need[@]}"; do command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found in PATH"; done
python3 - <<'PY' || die "pandoc-plantuml-filter not installed (pip install pandoc-plantuml-filter)"
import importlib; importlib.import_module("pandoc_plantuml_filter")
PY
command -v dot >/dev/null 2>&1 || warn "'dot' (Graphviz) not found. Some diagrams may render differently."

# PlantUML behavior
export PLANTUML_BIN="plantuml -failfast2 -charset UTF-8"

# --- config files (kept next to the script) --------------------------------
DEFAULTS="$SCRIPT_DIR/pandoc-pdf.yaml"     # YAML should say: include-in-header: [header.tex]
LUA_FILTER="$SCRIPT_DIR/emoji-textemoji.lua"
FONTS_TEX="$SCRIPT_DIR/fonts.tex"          # optional
HEADER_TEX="$SCRIPT_DIR/header.tex"        # used only as fallback if no defaults

# Build a resource path that includes BOTH:
# - the input file's directory (images next to the .md)
# - the script directory (header.tex, other shared assets)
INPUT_DIR="$(cd -P "$(dirname "$INPUT")" >/dev/null 2>&1 && pwd)"
RESOURCE_PATH="${INPUT_DIR}:${SCRIPT_DIR}"

# --- assemble pandoc command ----------------------------------------------
args=()
args+=("$INPUT" -o "$OUTPUT")
args+=(--standalone)
args+=(--pdf-engine=xelatex)
args+=(--resource-path="$RESOURCE_PATH")
args+=(--filter pandoc-plantuml)

# Use defaults if present; otherwise include header.tex directly
if [[ -f "$DEFAULTS" ]]; then
  args+=(--defaults="$DEFAULTS")
else
  warn "Defaults not found: $DEFAULTS (using fallback header includes)"
  [[ -f "$HEADER_TEX" ]] && args+=(--include-in-header="$HEADER_TEX")
fi

# Lua filter (optional)
[[ -f "$LUA_FILTER" ]] && args+=(--lua-filter="$LUA_FILTER") || warn "Lua filter not found: $LUA_FILTER"

# fonts.tex (optional)
[[ -f "$FONTS_TEX" ]] && args+=(--include-in-header="$FONTS_TEX")

# --- run -------------------------------------------------------------------
echo "Converting '$INPUT' to '$OUTPUT'..."
pandoc "${args[@]}"
echo "✅ Done: $OUTPUT"
