# homebrew program is installed
if which brew; then
  # auto update every 24 hours
  export HOMEBREW_AUTO_UPDATE_SECS="86400"
fi
