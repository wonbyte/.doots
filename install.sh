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
read -r -a folders <<< "${STOW_FOLDERS//,/ }"

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
pushd "${HOME}/.doots" >/dev/null 2>&1

# Unstow and then restow each folder
for folder in "${folders[@]}"; do
    # Unstow (don't fail if nothing was previously stowed)
    stow -D "$folder" || true

    # Stow the current folder
    stow "$folder"
done

# Return to the original directory
popd >/dev/null 2>&1 || true

echo "Stow operations completed successfully."
