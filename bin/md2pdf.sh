#!/usr/bin/env bash
# version 1.0.0
# Thu Nov  6 13:09:28 PST 2025
set -Eeuo pipefail

# --- helpers ---------------------------------------------------------------
die() { echo "Error: $*" >&2; exit 1; }

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
  # robust default: same dir as input
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

# Optional: Graphviz helps with some diagram layouts
if ! command -v dot >/dev/null 2>&1; then
  echo "Warning: 'dot' (Graphviz) not found. Some diagrams may render differently." >&2
fi

# Make PlantUML fail clearly and use UTF‑8; pandoc-plantuml will append -t<png/svg>
export PLANTUML_BIN="plantuml -failfast2 -charset UTF-8"

# --- run -------------------------------------------------------------------
echo "Converting '$INPUT' to '$OUTPUT'..."
pandoc "$INPUT" \
  -o "$OUTPUT" \
  --standalone \
  --pdf-engine=xelatex \
  --resource-path="$(dirname "$INPUT")" \
  --lua-filter=/Users/bernd/.dotfiles/bin/emoji-textemoji.lua \
  --include-in-header=/Users/bernd/.dotfiles/bin/fonts.tex \
  --filter pandoc-plantuml

echo "✅ Done: $OUTPUT"

