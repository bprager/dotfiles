#!/usr/bin/env bash
# version 1.6.0
# Mon Dec 15 2025
# md2pdf.sh
# Convert Markdown to PDF with optional header (letterhead), PlantUML, emoji and Unicode support, XeLaTeX.

set -Eeuo pipefail

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }
info() { echo "$*" >&2; }

usage() {
  cat >&2 <<'TXT'
Usage:
  md2pdf.sh [--header[=HEADER.md]] <file.md> [out.pdf]

Examples:
  md2pdf.sh main.md
  md2pdf.sh main.md out.pdf
  md2pdf.sh main.md --header=letterhead.md
  md2pdf.sh --header=letterhead.md main.md
  md2pdf.sh --header main.md              # uses MD2PDF_HEADER (or .env lookup)
  md2pdf.sh --header -- main.md out.pdf   # explicit end of options

Env:
  MD2PDF_KEEP_TMP=1        Keep temporary work directory for debugging
  MD2PDF_DEBUG=1           Print the full pandoc command
  MD2PDF_FORCE_LOCAL_LUA=1 Use emoji-textemoji.lua next to this script (unsafe if it contains Unicode [] classes)
  MD2PDF_HEADER=<path>     Default header markdown file (only used when --header is present without a value)
TXT
}


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

# Args
HEADER_ENV_VAR="MD2PDF_HEADER"

trim_ws() {
  local s="$1"
  s="${s#"${s%%[!$' 	
']*}"}"
  s="${s%"${s##*[!$' 	
']}"}"
  printf '%s' "$s"
}

# Extract KEY from a .env file without executing it.
# Supports lines like:
#   KEY=value
#   export KEY=value
#   KEY="value with spaces"
# Keeps the last occurrence of KEY in the file.
dotenv_get_value() {
  local env_file="$1"
  local key="$2"
  local line k v found=""

  [[ -f "$env_file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'
'}"
    line="$(trim_ws "$line")"
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue

    if [[ "$line" == export$' '* || "$line" == export$'	'* ]]; then
      line="${line#export}"
      line="$(trim_ws "$line")"
    fi

    [[ "$line" == *"="* ]] || continue
    k="$(trim_ws "${line%%=*}")"
    v="$(trim_ws "${line#*=}")"
    [[ "$k" == "$key" ]] || continue

    # Strip inline comments for unquoted values ("..." and '...' keep # as data)
    if [[ "$v" != '"'* && "$v" != "'"* ]]; then
      v="${v%%[[:space:]]#*}"
      v="$(trim_ws "$v")"
    fi

    # Strip surrounding quotes
    if [[ "$v" == '"'*'"' ]]; then
      v="${v#\"}"
      v="${v%\"}"
    elif [[ "$v" == "'"*"'" ]]; then
      v="${v#\'}"
      v="${v%\'}"
    fi

    found="$v"
  done <"$env_file"

  [[ -n "${found// }" ]] || return 1
  printf '%s' "$found"
  return 0
}

FOUND_DOTENV_FILE=""
find_dotenv_value_upwards() {
  local start_dir="$1"
  local key="$2"
  local dir val

  FOUND_DOTENV_FILE=""
  dir="$(cd -P "$start_dir" >/dev/null 2>&1 && pwd)" || return 1

  while true; do
    if [[ -f "$dir/.env" ]]; then
      if val="$(dotenv_get_value "$dir/.env" "$key")"; then
        FOUND_DOTENV_FILE="$dir/.env"
        printf '%s' "$val"
        return 0
      fi
    fi

    [[ "$dir" == "/" ]] && break
    dir="$(dirname "$dir")"
  done

  if [[ -n "${HOME:-}" && -f "$HOME/.env" ]]; then
    if val="$(dotenv_get_value "$HOME/.env" "$key")"; then
      FOUND_DOTENV_FILE="$HOME/.env"
      printf '%s' "$val"
      return 0
    fi
  fi

  return 1
}

expand_path() {
  local p="$1"
  local base_dir="$2"
  p="$(trim_ws "$p")"
  p="${p%$'
'}"

  if [[ "$p" == "~" ]]; then
    p="${HOME:-$p}"
  elif [[ "$p" == "~/"* ]]; then
    p="${HOME:-~}/${p#~/}"
  fi

  if [[ "$p" != /* && "$p" != "~"* ]]; then
    p="$base_dir/$p"
  fi

  printf '%s' "$p"
}

HEADER_REQUESTED=0
HEADER_VALUE=""
HEADER_SOURCE=""
HEADER_BASE_DIR=""
positional=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --header)
      HEADER_REQUESTED=1

      # Optional value handling:
      # If input is not known yet, only treat the next token as a header value when an input markdown file still remains afterwards.
      if [[ $# -ge 2 ]]; then
        next="${2:-}"
        if [[ "$next" != "--" && "$next" != -* ]]; then
          if [[ ${#positional[@]} -ge 1 ]]; then
            HEADER_VALUE="$next"
            shift 2
            continue
          fi

          if [[ $# -ge 3 && "${3:-}" == "--" ]]; then
            HEADER_VALUE="$next"
            shift 2
            continue
          fi

          if [[ $# -ge 3 ]]; then
            after="${3:-}"
            if [[ "$after" == *.md || "$after" == *.markdown ]]; then
              HEADER_VALUE="$next"
              shift 2
              continue
            fi
          fi
        fi
      fi

      HEADER_VALUE=""
      shift
      ;;
    --header=*)
      HEADER_REQUESTED=1
      HEADER_VALUE="${1#--header=}"
      shift
      ;;
    --)
      shift
      positional+=("$@")
      break
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done

if [[ ${#positional[@]} -lt 1 || ${#positional[@]} -gt 2 ]]; then
  usage
  exit 1
fi

INPUT="${positional[0]}"
[[ -f "$INPUT" ]] || die "File not found: $INPUT"
[[ "$INPUT" == *.md || "$INPUT" == *.markdown ]] || die "Input must end with .md or .markdown"
ORIGINAL_INPUT="$INPUT"

OUTPUT=""
if [[ ${#positional[@]} -eq 2 ]]; then
  OUTPUT="${positional[1]}"
else
  OUTPUT="${INPUT%.*}.pdf"
fi

[[ -n "${OUTPUT// }" ]] || die "Output path resolved to empty"
mkdir -p "$(dirname "$OUTPUT")"

LETTERHEAD=""

if [[ "$HEADER_REQUESTED" -eq 1 ]]; then
  header_raw=""
  base_dir="$(pwd)"
  HEADER_BASE_DIR="$base_dir"

  if [[ -n "${HEADER_VALUE:-}" ]]; then
    header_raw="$HEADER_VALUE"
    HEADER_SOURCE="command line"
  else
    if [[ -n "${!HEADER_ENV_VAR:-}" ]]; then
      header_raw="${!HEADER_ENV_VAR}"
      HEADER_SOURCE="env:$HEADER_ENV_VAR"
    else
      if header_raw="$(find_dotenv_value_upwards "$base_dir" "$HEADER_ENV_VAR")"; then
        HEADER_SOURCE="${FOUND_DOTENV_FILE}"
        HEADER_BASE_DIR="$(cd -P "$(dirname "$FOUND_DOTENV_FILE")" >/dev/null 2>&1 && pwd)"
      else
        die "--header was provided without a value, but '$HEADER_ENV_VAR' was not found in the shell environment, any .env from the current directory up to '/', or \$HOME/.env"
      fi
    fi
  fi

  header_path="$(expand_path "$header_raw" "$HEADER_BASE_DIR")"
  [[ -f "$header_path" ]] || die "Header file not found: $header_path (from $HEADER_SOURCE)"
  [[ "$header_path" == *.md || "$header_path" == *.markdown ]] || die "Header must end with .md or .markdown: $header_path"
  LETTERHEAD="$header_path"
fi


# Pick python
PYTHON=""
if command -v pyenv >/dev/null 2>&1; then
  PYTHON="$(pyenv which python 2>/dev/null || true)"
fi
if [[ -z "${PYTHON:-}" ]]; then
  PYTHON="$(command -v python3 2>/dev/null || true)"
fi
if [[ -z "${PYTHON:-}" ]]; then
  PYTHON="$(command -v python 2>/dev/null || true)"
fi
[[ -n "${PYTHON:-}" ]] || die "python3 not found"

# Tools
need=(pandoc xelatex plantuml)
for cmd in "${need[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found in PATH"
done

# Pandoc PlantUML filter must exist as an executable, and import should work too
command -v pandoc-plantuml >/dev/null 2>&1 || die "'pandoc-plantuml' not found in PATH (pip install pandoc-plantuml-filter)"
"$PYTHON" - <<'PY' >/dev/null 2>&1 || die "pandoc-plantuml-filter not installed for this python (pip install pandoc-plantuml-filter)"
import importlib
importlib.import_module("pandoc_plantuml_filter")
PY

command -v dot >/dev/null 2>&1 || warn "'dot' (Graphviz) not found, some diagrams may render differently"

# PlantUML behavior
export PLANTUML_BIN="plantuml -failfast2 -charset UTF-8"

# Work dir
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/md2pdf-work-XXXXXX")"
cleanup() {
  local rc=$?
  if [[ "${MD2PDF_KEEP_TMP:-}" == "1" ]]; then
    info "Keeping temp dir: $WORKDIR"
  else
    rm -rf "$WORKDIR" >/dev/null 2>&1 || true
  fi
  exit "$rc"
}
trap cleanup EXIT

# Config files (expected next to the script)
DEFAULTS="$SCRIPT_DIR/pandoc-pdf.yaml"
LOCAL_LUA_FILTER="$SCRIPT_DIR/emoji-textemoji.lua"
FONTS_TEX="$SCRIPT_DIR/fonts.tex"
HEADER_TEX="$SCRIPT_DIR/header.tex"

# Sanitize Unicode punctuation in input (do not touch arrows here)
SANITIZED_INPUT="$WORKDIR/input.sanitized.md"
"$PYTHON" - "$INPUT" "$SANITIZED_INPUT" <<'PY'
import sys, pathlib

src_path = pathlib.Path(sys.argv[1])
dst_path = pathlib.Path(sys.argv[2])

text = src_path.read_text(encoding="utf-8")

repl = {
    # hyphens, dashes, minus
    "\u2010": "-",  # hyphen
    "\u2011": "-",  # non breaking hyphen
    "\u2012": "-",  # figure dash
    "\u2013": "-",  # en dash
    "\u2014": "-",  # em dash
    "\u2212": "-",  # minus sign

    # smart single quotes
    "\u2018": "'",
    "\u2019": "'",
    "\u201B": "'",

    # smart double quotes
    "\u201C": '"',
    "\u201D": '"',
    "\u201F": '"',

    # variation selectors (strip)
    "\uFE0F": "",
    "\uFE0E": "",
}

for k, v in repl.items():
    text = text.replace(k, v)

dst_path.write_text(text, encoding="utf-8")
PY

INPUT="$SANITIZED_INPUT"

# Resource path
INPUT_DIR="$(cd -P "$(dirname "$INPUT")" >/dev/null 2>&1 && pwd)"
RESOURCE_PATH="${INPUT_DIR}:${SCRIPT_DIR}"

LETTERHEAD_DIR=""
if [[ -n "${LETTERHEAD:-}" ]]; then
  LETTERHEAD_DIR="$(cd -P "$(dirname "$LETTERHEAD")" >/dev/null 2>&1 && pwd)"
  if [[ "$LETTERHEAD_DIR" != "$INPUT_DIR" && "$LETTERHEAD_DIR" != "$SCRIPT_DIR" ]]; then
    RESOURCE_PATH="${RESOURCE_PATH}:${LETTERHEAD_DIR}"
  fi
fi

# Allow images next to letterhead
TMP_GRAPHICS_HEADER=""
if [[ -n "${LETTERHEAD:-}" ]]; then
  [[ -n "$LETTERHEAD_DIR" ]] || LETTERHEAD_DIR="$(cd -P "$(dirname "$LETTERHEAD")" >/dev/null 2>&1 && pwd)"
  TMP_GRAPHICS_HEADER="$WORKDIR/graphics-path.tex"
  cat >"$TMP_GRAPHICS_HEADER" <<EOF
% Auto generated, allow images next to letterhead
\\graphicspath{{$LETTERHEAD_DIR/}}
EOF
fi

# Arrow and macro overrides, included last in header
# This fixes cases where fonts.tex defines \symbolarrow via a font that lacks the glyph,
# and also protects PDF strings via texorpdfstring fallback.
TMP_OVERRIDES_HEADER="$WORKDIR/overrides.tex"
cat >"$TMP_OVERRIDES_HEADER" <<'TEX'
% Auto generated by md2pdf.sh
\usepackage{newunicodechar}
\providecommand{\texorpdfstring}[2]{#1}

% Make sure \symbolarrow always works and does not depend on a particular text font
\providecommand{\symbolarrow}{}
\renewcommand{\symbolarrow}{\texorpdfstring{\ensuremath{\rightarrow}}{->}}

% If any raw Unicode arrows survive, map them too
\newunicodechar{→}{\symbolarrow{}}
\newunicodechar{➝}{\symbolarrow{}}

% If emoji macros are missing, provide minimal fallbacks so compilation still succeeds
\providecommand{\textemoji}[1]{#1}
\providecommand{\emojicheckmark}{\textemoji{✅}}
\providecommand{\emojicrossmark}{\textemoji{❌}}
\providecommand{\emojitarget}{\textemoji{🎯}}
\providecommand{\emojifilm}{\textemoji{🎬}}
\providecommand{\emojivideo}{\textemoji{📹}}
\providecommand{\emojibrain}{\textemoji{🧠}}
\providecommand{\emojitool}{\textemoji{🔧}}
\providecommand{\emojimegaphone}{\textemoji{📣}}
\providecommand{\emojichart}{\textemoji{📈}}
\providecommand{\emojisearch}{\textemoji{🔍}}
\providecommand{\emojisoon}{\textemoji{🔜}}
\providecommand{\emojimakeup}{\textemoji{💄}}
\providecommand{\emojihandshake}{\textemoji{🤝}}
\providecommand{\emojithought}{\textemoji{💭}}
\providecommand{\emojidice}{\textemoji{🎲}}
\providecommand{\emojiSeedling}{\textemoji{🌱}}
\providecommand{\emojiGlobe}{\textemoji{🌐}}
TEX

# Choose Lua filter
# If the local filter contains known unsafe patterns (Unicode inside [] classes, or gsub("", "")),
# we ignore it and use a generated UTF-8 safe filter that also handles arrows inside longer tokens.
SAFE_LUA_FILTER="$WORKDIR/md2pdf-safe-emoji.lua"
cat >"$SAFE_LUA_FILTER" <<'LUA'
-- md2pdf-safe-emoji.lua
-- UTF-8 safe Pandoc Lua filter for LaTeX output:
-- 1) normalizes a few punctuation characters safely
-- 2) rewrites arrows, math-ish symbols, and selected emojis to LaTeX macros
-- 3) normalizes code and code blocks (arrows become -> in code)

local function replace_all_literal(s, map)
  for k, v in pairs(map) do
    s = s:gsub(k, v)
  end
  return s
end

local TEXT_NORMALIZE = {
  ["\u{2010}"] = "-",  -- hyphen
  ["\u{2011}"] = "-",  -- non-breaking hyphen
  ["\u{2013}"] = "-",  -- en dash
  ["\u{2014}"] = "-",  -- em dash
  ["\u{2212}"] = "-",  -- minus sign

  ["\u{2018}"] = "'",  -- left single quote
  ["\u{2019}"] = "'",  -- right single quote
  ["\u{201C}"] = '"',  -- left double quote
  ["\u{201D}"] = '"',  -- right double quote
}

local function strip_variation_selectors(s)
  s = s:gsub("\u{FE0F}", "")
  s = s:gsub("\u{FE0E}", "")
  s = s:gsub("️", "")
  return s
end

local function normalize_text(s)
  s = replace_all_literal(s, TEXT_NORMALIZE)
  s = strip_variation_selectors(s)
  return s
end

local function normalize_code(s)
  s = normalize_text(s)
  s = s:gsub("→", "->")
  s = s:gsub("➝", "->")
  return s
end

function Code(el)
  if FORMAT == "latex" then
    el.text = normalize_code(el.text)
  end
  return el
end

function CodeBlock(el)
  if FORMAT == "latex" then
    el.text = normalize_code(el.text)
  end
  return el
end

local INLINE_MAP = {
  ["→"] = pandoc.RawInline("latex", "\\symbolarrow{}"),
  ["➝"] = pandoc.RawInline("latex", "\\symbolarrow{}"),
  ["≤"] = pandoc.RawInline("latex", "\\ensuremath{\\le{}}"),
  ["≈"] = pandoc.RawInline("latex", "\\ensuremath{\\approx{}}"),

  ["✅"] = pandoc.RawInline("latex", "\\emojicheckmark{}"),
  ["❌"] = pandoc.RawInline("latex", "\\emojicrossmark{}"),
  ["🎯"] = pandoc.RawInline("latex", "\\emojitarget{}"),
  ["🎬"] = pandoc.RawInline("latex", "\\emojifilm{}"),
  ["📹"] = pandoc.RawInline("latex", "\\emojivideo{}"),
  ["🎥"] = pandoc.RawInline("latex", "\\emojivideo{}"),
  ["🧠"] = pandoc.RawInline("latex", "\\emojibrain{}"),
  ["🔧"] = pandoc.RawInline("latex", "\\emojitool{}"),
  ["🛠"] = pandoc.RawInline("latex", "\\emojitool{}"),
  ["📣"] = pandoc.RawInline("latex", "\\emojimegaphone{}"),
  ["📈"] = pandoc.RawInline("latex", "\\emojichart{}"),
  ["🔍"] = pandoc.RawInline("latex", "\\emojisearch{}"),
  ["🔜"] = pandoc.RawInline("latex", "\\emojisoon{}"),
  ["💄"] = pandoc.RawInline("latex", "\\emojimakeup{}"),
  ["🤝"] = pandoc.RawInline("latex", "\\emojihandshake{}"),
  ["💭"] = pandoc.RawInline("latex", "\\emojithought{}"),
  ["🎲"] = pandoc.RawInline("latex", "\\emojidice{}"),
  ["🌱"] = pandoc.RawInline("latex", "\\emojiSeedling{}"),
  ["🌐"] = pandoc.RawInline("latex", "\\emojiGlobe{}"),
}

local function rewrite_str_to_inlines(s)
  local out = pandoc.List()
  local buf = ""

  for _, cp in utf8.codes(s) do
    local ch = utf8.char(cp)
    local repl = INLINE_MAP[ch]
    if repl then
      if buf ~= "" then
        out:insert(pandoc.Str(buf))
        buf = ""
      end
      out:insert(repl)
    else
      buf = buf .. ch
    end
  end

  if buf ~= "" then
    out:insert(pandoc.Str(buf))
  end

  return out
end

function Str(el)
  if FORMAT ~= "latex" then return nil end
  local s = normalize_text(el.text)

  -- Only rewrite if needed, otherwise keep Pandoc defaults
  if not (
    s:find("→", 1, true) or s:find("➝", 1, true) or
    s:find("≤", 1, true) or s:find("≈", 1, true) or
    s:find("✅", 1, true) or s:find("❌", 1, true) or
    s:find("🎯", 1, true) or s:find("🎬", 1, true) or
    s:find("📹", 1, true) or s:find("🎥", 1, true) or
    s:find("🧠", 1, true) or s:find("🔧", 1, true) or
    s:find("🛠", 1, true) or s:find("📣", 1, true) or
    s:find("📈", 1, true) or s:find("🔍", 1, true) or
    s:find("🔜", 1, true) or s:find("💄", 1, true) or
    s:find("🤝", 1, true) or s:find("💭", 1, true) or
    s:find("🎲", 1, true) or s:find("🌱", 1, true) or
    s:find("🌐", 1, true)
  ) then
    el.text = s
    return el
  end

  return rewrite_str_to_inlines(s)
end
LUA

LUA_FILTER_EFFECTIVE="$SAFE_LUA_FILTER"

if [[ "${MD2PDF_FORCE_LOCAL_LUA:-}" == "1" ]]; then
  [[ -f "$LOCAL_LUA_FILTER" ]] || die "MD2PDF_FORCE_LOCAL_LUA=1 but no local filter found: $LOCAL_LUA_FILTER"
  LUA_FILTER_EFFECTIVE="$LOCAL_LUA_FILTER"
else
  if [[ -f "$LOCAL_LUA_FILTER" ]]; then
    if grep -Fq ':gsub("", "")' "$LOCAL_LUA_FILTER" || grep -Fq 'gsub("[\u{' "$LOCAL_LUA_FILTER"; then
      warn "Local Lua filter looks unsafe for UTF-8 arrows, using generated safe filter"
    else
      LUA_FILTER_EFFECTIVE="$LOCAL_LUA_FILTER"
    fi
  fi
fi

# Assemble pandoc args
args=()
args+=(-f markdown+raw_tex+tex_math_single_backslash-smart)
args+=(--standalone)
args+=(--pdf-engine=xelatex)
args+=(--pdf-engine-opt=-halt-on-error)
args+=(--pdf-engine-opt=-file-line-error)
args+=(--pdf-engine-opt=-interaction=nonstopmode)
args+=(--resource-path="$RESOURCE_PATH")

# Defaults
if [[ -f "$DEFAULTS" ]]; then
  args+=(--defaults="$DEFAULTS")
else
  [[ -f "$HEADER_TEX" ]] && args+=(--include-in-header="$HEADER_TEX")
fi

# Header before body
if [[ -n "${LETTERHEAD:-}" ]]; then
  args+=(-B "$LETTERHEAD")
fi

# Header includes, order matters, overrides last
if [[ -n "$TMP_GRAPHICS_HEADER" && -f "$TMP_GRAPHICS_HEADER" ]]; then
  args+=(--include-in-header="$TMP_GRAPHICS_HEADER")
fi
[[ -f "$FONTS_TEX" ]] && args+=(--include-in-header="$FONTS_TEX")
args+=(--include-in-header="$TMP_OVERRIDES_HEADER")

# Filters, order matters, Lua filter last
args+=(--filter pandoc-plantuml)
args+=(--lua-filter="$LUA_FILTER_EFFECTIVE")

# Input and output
args+=("$INPUT")
args+=(-o "$OUTPUT")

info "Converting '$ORIGINAL_INPUT' to '$OUTPUT'"
if [[ -n "${LETTERHEAD:-}" ]]; then
  info "Using header: '$LETTERHEAD'"
fi

if [[ "${MD2PDF_DEBUG:-}" == "1" ]]; then
  info "pandoc ${args[*]}"
fi

pandoc "${args[@]}"

info "✅ Done: $OUTPUT"

