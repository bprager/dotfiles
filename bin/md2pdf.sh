#!/usr/bin/env bash

set -e

# Helper to check Python package
check_python_package() {
  python3 -c "import $1" 2>/dev/null
}

# 1. Check argument
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file.md>"
  exit 1
fi

INPUT="$1"

# 2. Check file exists
if [[ ! -f "$INPUT" ]]; then
  echo "Error: File '$INPUT' not found."
  exit 1
fi

# 3. Check markdown extension
if [[ "$INPUT" != *.md && "$INPUT" != *.markdown ]]; then
  echo "Error: File must have .md or .markdown extension."
  exit 1
fi

# 4. Check required tools
REQUIRED_CMDS=("python3" "pandoc" "xelatex")
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required tool '$cmd' is not installed or not in PATH."
    exit 1
  fi
done

# Check if pandoc-plantuml-filter is available in Python
if ! python3 -c "import pandoc_plantuml_filter" 2>/dev/null; then
  echo "Error: pandoc-plantuml-filter is not installed."
  echo "Hint: Try 'pip install pandoc-plantuml-filter' in your virtual environment."
  exit 1
fi

# 5. Generate output filename
BASENAME=$(basename "$INPUT")
OUTPUT="${BASENAME%.*}.pdf"

# 6. Convert using pandoc
echo "Converting '$INPUT' to '$OUTPUT'..."
pandoc "$INPUT" \
  -o "$OUTPUT" \
  --pdf-engine=xelatex \
  --lua-filter=/Users/bernd/.dotfiles/bin/emoji-textemoji.lua \
  --include-in-header=/Users/bernd/.dotfiles/bin/fonts.tex \
  --filter pandoc-plantuml

echo "✅ Done: $OUTPUT created."

