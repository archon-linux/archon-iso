#!/usr/bin/env bash
# archon-iso
# https://github.com/archon-linux/archon-iso
# @nekwebdev
# LICENSE: GPLv3
set -e

###### EDIT ME #################################################################

git_url="https://github.com/archon-linux/archon-dotfiles.git"

################################################################################

###### => variables ############################################################
cd "$(dirname "$0")" || exit 1
current_dir="$(pwd)"

###### => main #################################################################
# check if our dotfiles folder is already there
[[ -d "${current_dir}/dotfiles" ]] && echo 'dotfiles folder already present' && exit 1

# make the bare repository directory
mkdir -p "${current_dir}/dotfiles/.dotfiles"

# initialize the git bare repository
git init --bare "${current_dir}/dotfiles/.dotfiles"

# offer alias
archondots="/usr/bin/git --git-dir=${current_dir}/dotfiles/.dotfiles --work-tree=${current_dir}/dotfiles"
echo
echo "Think about creating this alias:"
echo "alias archondots=\"${archondots}\""
echo

# hide untracked files
$archondots config status.showUntrackedFiles no

# add our remote
$archondots remote add origin "$git_url"
$archondots branch -m main
$archondots pull origin main

echo
echo "Done."
echo

exit 0
