# ~/.zshrc.d/20-python-local.zsh

PY_LOCAL_ROOT="$HOME/.local"

# (/N) means, match directories only, expand to nothing if there are no matches
for dir in "$PY_LOCAL_ROOT"/python-*(/N); do
  ver="${dir##*/python-}"
  short_ver="${ver//./}"

  [[ -x "$dir/bin/python3" ]] && alias "python${short_ver}"="$dir/bin/python3"
  [[ -x "$dir/bin/pip3"    ]] && alias "pip${short_ver}"="$dir/bin/pip3"
done

