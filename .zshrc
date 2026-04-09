# Path to your oh-my-zsh installation
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Detect OS once
os_name="$(uname -s)"

typeset -U path fpath

path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path=("$dir" $path)
}

path_append() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path+=("$dir")
}

fpath_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  fpath=("$dir" $fpath)
}

# Base PATH
path_prepend "/usr/local/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.npm-global/bin"
path_append "$HOME/go/bin"

# Homebrew completion (macOS only)
if [[ "$os_name" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix 2>/dev/null)"
  [[ -n $brew_prefix ]] && fpath_prepend "$brew_prefix/share/zsh/site-functions"
  unset brew_prefix
fi

# User functions
if [[ -d "$HOME/.zfunc" ]]; then
  fpath_prepend "$HOME/.zfunc"
  autoload -Uz "$HOME"/.zfunc/*(:t)
fi

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
case "$os_name" in
  Linux)
    if [[ -d /usr/lib/x86_64-linux-gnu ]]; then
      export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
    export TF_CPP_MIN_LOG_LEVEL=2  # 0=all, 1=info, 2=warning, 3=error
    export GDK_BACKEND=x11
    ;;
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      util_linux_prefix="$(brew --prefix util-linux 2>/dev/null)"
      if [[ -n $util_linux_prefix ]]; then
        path_prepend "$util_linux_prefix/bin"
        path_prepend "$util_linux_prefix/sbin"
        export LDFLAGS="-L${util_linux_prefix}/lib${LDFLAGS:+ $LDFLAGS}"
        export CPPFLAGS="-I${util_linux_prefix}/include${CPPFLAGS:+ $CPPFLAGS}"
      fi

      gawk_prefix="$(brew --prefix gawk 2>/dev/null)"
      [[ -n $gawk_prefix ]] && path_prepend "$gawk_prefix/libexec/gnubin"

      nvm_prefix="$(brew --prefix nvm 2>/dev/null)"
      [[ -n $nvm_prefix && -s "$nvm_prefix/nvm.sh" ]] && source "$nvm_prefix/nvm.sh"

      unset util_linux_prefix gawk_prefix nvm_prefix
    fi
    ;;
  FreeBSD)
    ;;
esac

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
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
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
if [[ "$os_name" == "Darwin" ]]; then
  export ARCHFLAGS="-arch $(uname -m)"
fi

# Custom aliases
if [[ -f "$HOME/.aliases" ]]; then
  source "$HOME/.aliases"
fi

# Visual Studio Code launcher
code() {
  if whence -p code >/dev/null 2>&1; then
    command code "$@"
  elif [[ "$os_name" == "Darwin" ]]; then
    VSCODE_CWD="$PWD" open -n -b "${VSCODE_BUNDLE_ID:-com.microsoft.VSCode}" --args "$@"
  elif whence -p codium >/dev/null 2>&1; then
    command codium "$@"
  else
    print -u2 -- "code: Visual Studio Code CLI is not available"
    return 127
  fi
}

# nerdctl completion
if [[ -f "$HOME/bin/nerdctl_completion.zsh" ]]; then
  source "$HOME/bin/nerdctl_completion.zsh"
fi

# Completion style
zstyle ':completion:*' menu select

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
