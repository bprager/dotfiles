#!/usr/bin/env bash
# replace_en_space.sh
# Usage:  ./replace_en_space.sh file1 [file2 …]

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <file> [more files …]" >&2
  exit 1
fi

# Perl’s UTF-8 support is the most reliable way to do this on both GNU/Linux and macOS.
# -CS     → enable Unicode I/O
# -pi     → in-place edit (creates backup if you add e.g. -pi.bak)
# s///g   → substitute all occurrences
for f in "$@"; do
  perl -CS -Mutf8 -pi -e 's/\x{2002}/ /g' -- "$f"
done

