#!/bin/zsh
# Prepend date to one or more files/directories
dmv() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: dmv <file1> [file2 ...]"
    return 1
  fi
  for file in "$@"; do
    mv "$file" "$(date +%F)_${file:t}"
  done
}
