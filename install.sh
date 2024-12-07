#!/usr/bin/env bash
set -euo pipefail

# Specify the folders to stow, separated by commas.
export STOW_FOLDERS="bin,fish,nvim,starship,tmux"

# Ensure required directories exist
mkdir -p "${HOME}/.local" "${HOME}/.config"

# Validate STOW_FOLDERS is not empty
if [ -z "$STOW_FOLDERS" ]; then
    echo "Error: No folders specified in STOW_FOLDERS."
    exit 1
fi

# Convert the comma-separated list into an array by replacing commas with spaces
IFS=',' read -r -a folders <<< "$STOW_FOLDERS"

# Validate that we have at least one folder after splitting
if [ ${#folders[@]} -eq 0 ]; then
    echo "Error: No valid folders found after splitting STOW_FOLDERS."
    exit 1
fi

# Check if the .doots directory exists before trying to enter it
if [ ! -d "${HOME}/.doots" ]; then
    echo "Error: ${HOME}/.doots directory does not exist."
    exit 1
fi

# Move into the .doots directory
pushd "${HOME}/.doots" >/dev/null || exit 1

# Unstow and then restow each folder
for folder in "${folders[@]}"; do
    # Check if the folder exists in the .doots directory
    if [ ! -d "$folder" ]; then
        echo "Warning: Folder '$folder' does not exist in ${HOME}/.doots. Skipping."
        continue
    fi

    # Unstow (don't fail if nothing was previously stowed)
    stow -D "$folder" 2>/dev/null || true

    # Stow the current folder
    if ! stow "$folder"; then
        echo "Error: Failed to stow folder '$folder'."
        exit 1
    fi
done

# Return to the original directory
popd >/dev/null || exit 1

echo "Stow operations completed successfully."
