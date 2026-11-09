#!/usr/bin/env bash
set -euo pipefail

# Packages to stow. Each one is symlinked into $HOME via GNU Stow.
folders=(bin fish nvim starship tmux)

DOTFILES="${HOME}/.doots"

command -v stow >/dev/null || {
    echo "Error: GNU Stow is not installed." >&2
    exit 1
}

if [[ ! -d "$DOTFILES" ]]; then
    echo "Error: $DOTFILES does not exist." >&2
    exit 1
fi

# Make sure these exist as real directories, so Stow links the files
# inside them instead of linking the whole directory.
mkdir -p "${HOME}/.local/bin" "${HOME}/.config"

cd "$DOTFILES"

for folder in "${folders[@]}"; do
    if [[ ! -d "$folder" ]]; then
        echo "Warning: '$folder' not found in $DOTFILES. Skipping." >&2
        continue
    fi

    # -R (restow) = unstow then stow, which also prunes stale links.
    stow -R -t "$HOME" "$folder"
done

echo "Stow operations completed successfully."
