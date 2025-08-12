# ~/.zshrc.d/python312.zsh

# Use custom Python 3.12 installation if present
CUSTOM_PYTHON_DIR="$HOME/.local/python-3.12"

if [[ -d "$CUSTOM_PYTHON_DIR/bin" ]]; then
    export PATH="$CUSTOM_PYTHON_DIR/bin:$PATH"

    # Optional aliases
    alias python312="$CUSTOM_PYTHON_DIR/bin/python3"
    alias pip312="$CUSTOM_PYTHON_DIR/bin/pip3"
fi

