# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Detect OS once
os_name=$(uname)

# Homebrew completion (macOS only)
if [[ "$os_name" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

# User functions
if [[ -d "$HOME/.zfunc" ]]; then
  fpath=("$HOME/.zfunc" $fpath)
  autoload -Uz "$HOME"/.zfunc/*(:t)
fi

# Remove duplicates in fpath
typeset -U fpath

# Initialize completion only for interactive shells
if [[ $- == *i* ]]; then
  autoload -Uz compinit
  compinit -C
fi

# Custom inits
# Load extra zsh config snippets (pyenv etc)
for rc in "$HOME/.zshrc.d"/*.zsh(N); do
  source "$rc"
done

# OS specific configuration
if [[ "$os_name" == "Linux" ]]; then
  [[ $- == *i* ]] && echo "Running on Linux"
  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
  export TF_CPP_MIN_LOG_LEVEL=2  # 0=all, 1=info, 2=warning, 3=error
  # Allow GTK app using Wayland
  export GDK_BACKEND=x11
elif [[ "$os_name" == "Darwin" ]]; then
  [[ $- == *i* ]] && echo "Running on macOS"
  export PATH="/opt/homebrew/opt/util-linux/bin:/opt/homebrew/opt/util-linux/sbin:$PATH"
  export LDFLAGS="-L/opt/homebrew/opt/util-linux/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/util-linux/include"
  # GNU tools
  export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
  # Node version manager (only if installed)
  if command -v brew >/dev/null 2>&1 && [[ -s "$(brew --prefix nvm)/nvm.sh" ]]; then
    source "$(brew --prefix nvm)/nvm.sh"
  fi
elif [[ "$os_name" == "FreeBSD" ]]; then
  [[ $- == *i* ]] && echo "Running on FreeBSD"
else
  [[ $- == *i* ]] && echo "Unknown Operating System"
fi

# Base PATH (keeps your original intent, but avoids overriding later)
PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Theme
ZSH_THEME="robbyrussell"

# Oh My Zsh update settings
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 7

# Plugins
plugins=(
  aws colorize copyfile gh git gnu-utils golang
  gpg-agent gradle history keychain npm pip pipenv python
  ssh ssh-agent starship tmux zsh-autosuggestions
  zsh-syntax-highlighting
)

if [[ "$os_name" == "Darwin" ]]; then
  plugins+=(macos brew)
fi

# Load Oh My Zsh only if it exists
if [[ -d "$ZSH" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Virtualenv
virtualenv_info() {
  [[ -n "$VIRTUAL_ENV" ]] && echo "(${${VIRTUAL_ENV:t}}) "
}

# Locale
export LANG=en_US.UTF-8

# Preferred editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export SYSTEMD_EDITOR=vim
else
  export EDITOR='nvim'
  export SYSTEMD_EDITOR=vim
fi

export XAUTHORITY="$HOME/.Xauthority"

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Custom aliases
if [[ -f "$HOME/.aliases" ]]; then
  source "$HOME/.aliases"
fi

# Visual Studio Code launcher
code() {
  VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$@"
}

# nerdctl completion
if [[ -f "$HOME/bin/nerdctl_completion.zsh" ]]; then
  source "$HOME/bin/nerdctl_completion.zsh"
fi

# terraform alias
if ! command -v terraform >/dev/null 2>&1; then
  alias tf="terraform"
fi

# Completion style
zstyle ':completion:*' menu select

# Go bin folder and user bin
export PATH="$PATH:$HOME/bin:$HOME/go/bin"

# Starship (interactive only)
if [[ $- == *i* ]]; then
  eval "$(starship init zsh)"
fi

# Local environment overrides
if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi

# SDKMAN (must be at end)
if [[ -d "$HOME/.sdkman" ]]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

export AWS_PAGER=""

