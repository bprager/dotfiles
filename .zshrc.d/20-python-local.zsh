# ~/.zshrc.d/20-python-local.zsh

# Look for locally built Pythons in ~/.local/python-*
PY_LOCAL_ROOT="$HOME/.local"

for dir in "$PY_LOCAL_ROOT"/python-*; do
  # Skip if glob did not match anything or dir has no bin
  [[ -d "$dir/bin" ]] || continue

  # Extract version suffix, e.g. python-3.12 -> 3.12
  ver="${dir##*/python-}"

  # Normalized alias name, e.g. 3.12 -> 312
  short_ver="${ver//./}"

  # Do not touch PATH, just provide explicit aliases
  alias "python${short_ver}"="$dir/bin/python3"
  alias "pip${short_ver}"="$dir/bin/pip3"
done

