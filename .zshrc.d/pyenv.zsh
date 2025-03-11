# Load pyenv-virtualenv automatically if available
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d $PYENV_ROOT/bin ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    # Check if virtualenv-init is available before running it
    if command -v pyenv virtualenv-init &> /dev/null; then
        eval "$(pyenv virtualenv-init -)"
    fi
fi

