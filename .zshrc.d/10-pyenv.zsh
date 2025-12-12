# ~/.zshrc.d/10-pyenv.zsh

# Only run if pyenv is installed
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

  # Put pyenv itself on PATH
  if [[ -d "$PYENV_ROOT/bin" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
  fi

  # Initialize shims (only in interactive shells)
  if [[ -n $PS1 ]]; then
    eval "$(pyenv init -)"
    # Optional: load pyenv-virtualenv if present
    if pyenv commands 2>/dev/null | grep -q '^virtualenv$'; then
      eval "$(pyenv virtualenv-init -)"
    fi
  fi
fi

