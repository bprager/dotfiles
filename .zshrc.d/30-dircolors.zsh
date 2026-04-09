# enable color support of ls and add some handy aliases
case "$os_name" in
  Linux)
    if command -v dircolors >/dev/null 2>&1; then
      [[ -r "$HOME/.dircolors" ]] && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -n)"
      LS_COLORS+=':ow=01;34'
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'
      alias fgrep='fgrep --color=auto'
      alias egrep='egrep --color=auto'
    fi
    ;;
  Darwin|FreeBSD)
    export CLICOLOR=1
    export LSCOLORS="${LSCOLORS:-ExFxBxDxCxegedabagacad}"
    alias ls='ls -G'
    ;;
esac
