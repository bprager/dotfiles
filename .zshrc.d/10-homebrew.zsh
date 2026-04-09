homebrew_prefix=""

for brew_bin in \
  "$HOME/homebrew/bin/brew" \
  "/opt/homebrew/bin/brew" \
  "/usr/local/bin/brew" \
  "$HOME/.linuxbrew/bin/brew" \
  "/home/linuxbrew/.linuxbrew/bin/brew"
do
  if [[ -x $brew_bin ]]; then
    homebrew_prefix="${brew_bin:h:h}"
    break
  fi
done

if [[ -z $homebrew_prefix ]] && command -v brew >/dev/null 2>&1; then
  homebrew_prefix="$(brew --prefix 2>/dev/null)"
fi

if [[ -z $homebrew_prefix && -d "$HOME/homebrew" ]]; then
  homebrew_prefix="$HOME/homebrew"
fi

if [[ -n $homebrew_prefix ]]; then
  path_prepend "$homebrew_prefix/bin"
  export HOMEBREW_AUTO_UPDATE_SECS="86400"
fi

unset homebrew_prefix
