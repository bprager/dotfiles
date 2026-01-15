# homebrew program is installed
if [ -d "$HOME/homebrew" ]; then
  export PATH="$HOME/homebrew/bin/:$PATH"
elif [ -d "/opt/homebrew" ]; then
  export PATH="/opt/homebrew/bin/:$PATH"
fi

# auto update every 24 hours if homebrew is installed
if [ -d "$HOME/homebrew" ] || [ -d "/opt/homebrew" ]; then
  export HOMEBREW_AUTO_UPDATE_SECS="86400"
fi

