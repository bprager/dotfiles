# ~/.zshrc.d/32-openclaw.zsh
# OpenClaw completion (cached)

if command -v openclaw >/dev/null 2>&1; then
  # Where to cache the generated completion file
  _oc_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/openclaw"
  _oc_comp_file="${_oc_cache_dir}/completion.zsh"
  _oc_bin="$(command -v openclaw)"

  mkdir -p "$_oc_cache_dir" 2>/dev/null

  # Refresh cache if missing, empty, or openclaw binary is newer
  if [[ ! -s "$_oc_comp_file" || "$_oc_bin" -nt "$_oc_comp_file" ]]; then
    if openclaw completion --shell zsh >| "$_oc_comp_file" 2>/dev/null; then
      true
    else
      rm -f "$_oc_comp_file" 2>/dev/null
    fi
  fi

  # Load completion if we have it
  if [[ -s "$_oc_comp_file" ]] && (( $+functions[compdef] )); then
    source "$_oc_comp_file"
  fi

  unset _oc_cache_dir _oc_comp_file _oc_bin
fi
