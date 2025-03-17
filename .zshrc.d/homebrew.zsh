# homebrew program is installed
if [ -d "$HOME/homebrew" ]; then
  export PATH="$HOME/homebrew/bin/:$PATH"
  # auto update every 24 hours
  export HOMEBREW_AUTO_UPDATE_SECS="86400"
fi
