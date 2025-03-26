#!/bin/zsh

# Define the function that renames files by replacing spaces with underscores
function rename_spaces {
    # Loop through each argument passed to the function
    for file in "$@"; do
        # Check if the file exists and the name contains spaces
        if [[ -e "$file" ]]; then
            # Replace spaces with underscores in the filename
            new_name="${file// /_}"
            # Only move if new name is different from the original
            if [[ "$new_name" != "$file" ]]; then
                mv -- "$file" "$new_name"
                echo "Renamed '$file' to '$new_name'"
            fi
        else
            echo "File does not exist: $file"
        fi
    done
}

# Export the function if you want it to be available in subshells
typeset -fx rename_spaces

# Usage message
echo "Usage: rename_spaces <file1> <file2> ... <fileN>"
echo "       rename_spaces '*' to replace spaces in all filenames in the current directory."

