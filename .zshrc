# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Add Homebrew's shell completion directory to fpath
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# functions
fpath=($HOME/.zfunc $fpath)

# Initialize Zsh completion system
autoload -Uz compinit; compinit

# Autoload all functions in the .zfunc directory
for func in $HOME/.zfunc/*(.); do
  autoload -Uz ${func:t}
done

# Custom inits
# Check if the .zshrc.d directory exists
if [[ -d "${HOME}/.zshrc.d" ]]; then
    # Source every file in the .zshrc.d directory
    for file in "${HOME}/.zshrc.d/"*; do
        [[ -f $file ]] && source $file
    done
fi

# Get the operating system name
os_name=$(uname)

# Conditional statements based on OS
if [[ "$os_name" == "Linux" ]]; then
  # Linux-specific configuration
  echo "Running on Linux"
elif [[ "$os_name" == "Darwin" ]]; then
  # macOS-specific configuration
  echo "Running on macOS"
  export PATH="/opt/homebrew/opt/util-linux/bin:$PATH"
  export PATH="/opt/homebrew/opt/util-linux/sbin:$PATH"
  export LDFLAGS="-L/opt/homebrew/opt/util-linux/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/util-linux/include"
  # Use gnu bins
  export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
  # node version manager
  source $(brew --prefix nvm)/nvm.sh
elif [[ "$os_name" == "FreeBSD" ]]; then
  # FreeBSD-specific configuration
  echo "Running on FreeBSD"
else
  echo "Unknown Operating System"
fi

# If you come from bash you might have to change your $PATH.
PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 7

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(aws colorize copyfile gh git gnu-utils golang)
plugins+=(gpg-agent gradle history keychain npm pip pipenv python)
plugins+=(ssh ssh-agent starship tmux zsh-autosuggestions)
plugins+=(zsh-syntax-highlighting)
if [[ "$os_name" == "Darwin" ]]; then
      plugins+=(macos brew)
fi

source $ZSH/oh-my-zsh.sh

# Virtualenv
function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export SYSTEMD_EDITOR=vim
else
  export EDITOR='nvim'
  export SYSTEMD_EDITOR=vim
fi
export XAUTHORITY=~/.Xauthority

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# Custom aliases
if [ -f ~/.aliases ]; then
  source ~/.aliases
fi

# Visual Studio Code
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}
# nerdctl
if [[ -f bin/nerdctl_completion.zsh ]]; then
  source bin/nerdctl_completion.zsh
fi
# terraform
if ! terraform_loc="$(type -p "$terraform")" || [[ -z $terraform_loc ]]; then
  alias tf="terraform"
fi

zstyle ':completion:*' menu select

# go bin folder
export PATH="$PATH:$HOME/bin:$HOME/go/bin"

#Starship
eval "$(starship init zsh)"

if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [[ -d "${HOME}/.sdkman" ]]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

