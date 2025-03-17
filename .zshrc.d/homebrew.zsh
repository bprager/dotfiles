# homebrew program is installed
if which brew >/dev/null 2>&1; then
  # auto update every 24 hours
  export PATH="$HOME/homebrew/bin/:$PATH"
  export HOMEBREW_AUTO_UPDATE_SECS="86400"
fi
