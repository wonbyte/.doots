# https://github.com/ThePrimeagen/.dotfiles/blob/master/install
export STOW_FOLDERS="bin,fish,nvim,starship,tmux"

pushd $HOME/.doots

for folder in $(echo $STOW_FOLDERS | /usr/bin/sed "s/,/ /g")
do
    stow -D $folder
    stow $folder
done
