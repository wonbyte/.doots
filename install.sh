#!/usr/bin/env bash
set -euo pipefail

# Folders to stow. The brew/ folder is intentionally excluded —
# Brewfiles don't need symlinking; run: brew bundle --file brew/Brewfile
STOW_FOLDERS="bin,fish,nvim,starship,tmux"

# Ensure required directories exist
mkdir -p "${HOME}/.local" "${HOME}/.config"

# Check if the .doots directory exists before trying to enter it
if [ ! -d "${HOME}/.doots" ]; then
    echo "Error: ${HOME}/.doots directory does not exist."
    exit 1
fi

# Convert the comma-separated list into an array
IFS=',' read -r -a folders <<< "$STOW_FOLDERS"

# Move into the .doots directory
pushd "${HOME}/.doots" >/dev/null || exit 1

# Unstow and then restow each folder
for folder in "${folders[@]}"; do
    if [ ! -d "$folder" ]; then
        echo "Warning: Folder '$folder' does not exist in ${HOME}/.doots. Skipping."
        continue
    fi

    # Unstow (don't fail if nothing was previously stowed)
    stow -D "$folder" || true

    # Stow the current folder
    if ! stow "$folder"; then
        echo "Error: Failed to stow folder '$folder'."
        exit 1
    fi
done

# Return to the original directory
popd >/dev/null || exit 1

echo "Stow operations completed successfully."
