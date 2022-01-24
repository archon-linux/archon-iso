#!/usr/bin/env bash
# archon-iso
# https://github.com/archon-linux/archon-iso
# @nekwebdev
# LICENSE: GPLv3
# Inspiration: Erik Dubois
# https://www.alci.online
set -e

###### => variables ############################################################
archisoRequiredVersion="archiso 60-1"
buildFolder="/tmp/archiso-tmp"
outFolder="${HOME}/archon-iso-out"
archisoVersion=$(sudo pacman -Q archiso)

###### => functions ############################################################
# echo_step() outputs a step collored in cyan, without outputing a newline.
function echo_step() {
	tput setaf 6 # 6 = cyan
	echo -n "$1"
	tput sgr 0 0  # reset terminal
}

# echo_equals() outputs a line with =
function echo_equals() {
	COUNTER=0
	while [  $COUNTER -lt "$1" ]; do
		printf '='
		(( COUNTER=COUNTER+1 ))
	done
}

# echo_title() outputs a title padded by =, in yellow.
function echo_title() {
	TITLE=$1
	NCOLS=$(tput cols)
	NEQUALS=$(((NCOLS-${#TITLE})/2-1))
	tput setaf 3 # 3 = yellow
	echo_equals "$NEQUALS"
	printf " %s " "$TITLE"
	echo_equals "$NEQUALS"
	tput sgr 0 0  # reset terminal
	echo
}

# echo_step_info() outputs additional step info in white, without a newline.
function echo_step_info() {
	tput setaf 7 # 7 = white
	echo -n " ($1)"
	tput sgr 0 0  # reset terminal
}

# echo_right() outputs a string at the rightmost side of the screen.
function echo_right() {
	TEXT=$1
	echo
	tput cuu1
	tput cuf "$(tput cols)"
	tput cub ${#TEXT}
	echo "$TEXT"
}

# echo_success() outputs [ OK ] in green, at the rightmost side of the screen.
function echo_success() {
	tput setaf 2 # 2 = green
	echo_right "[ OK ]"
	tput sgr 0 0  # reset terminal
}

# echo_failure() outputs [ FAILED ] in red, at the rightmost side of the screen.
function echo_failure() {
	tput setaf 1 # 1 = red
	echo_right "[ FAILED ]"
	tput sgr 0 0  # reset terminal
}

# exit_with_message() outputs and logs a message before exiting the script.
function exit_with_message() {
	echo
	echo "$1"
	echo
	exit 1
}

function find_and_replace() {
	find ${buildFolder}/archiso/profiledef.sh -type f -exec sed -i "/$1/a $2" {} \;
}

function copy_dotfiles() {
  if [[ ! -d "dotfiles" ]]; then
    echo_step_info "Cloning dotfiles"
    ./get_dotfiles.sh
    echo_step_info "Sleeping for 20 seconds so you can copy the alias" && sleep 20s
    echo_success
  fi

  echo_step_info "Copy dotfiles to the skel folder"
  cp -rf dotfiles "${buildFolder}/archiso/airootfs/etc/skel"; echo_success

	echo_step_info "Add dotfiles permissions to profiledef.sh"

	FIND='livecd-sound'
	find_and_replace $FIND '  ["/etc/skel/.ansible/playbooks/vault/run.sh"]="0:0:755"'
	find_and_replace $FIND '  ["/etc/skel/.config/gnupg"]="0:0:700"'
	find_and_replace $FIND '  ["/etc/skel/.config/gnupg/asc2gif.sh"]="0:0:755"'
	find_and_replace $FIND '  ["/etc/skel/.config/openbox/autostart"]="0:0:755"'
	find_and_replace $FIND '  ["/etc/skel/.config/VSCodium/User/extensions-list.sh"]="0:0:755"'

	# path folders
	etc_dir="${buildFolder}/archiso/airootfs/etc"
	scripts=$( find "${etc_dir}/skel/.local/bin/" -type f | sed 's!.*/!!' )
	for script in $scripts; do
	find_and_replace $FIND "  [\"/etc/skel/.local/bin/${script}\"]=\"0:0:755\""
	done

	scripts=$( find "${etc_dir}/skel/.local/scripts/" -type f -name "*.sh" | sed 's!.*/!!' )
	for script in $scripts; do
	find_and_replace $FIND "  [\"/etc/skel/.local/scripts/${script}\"]=\"0:0:755\""
	done

	echo_success
}

###### => main #################################################################
echo_title "Archon Linux ISO builder"; echo
# change working directory to script directory
cd "$(dirname "$0")" || exit 1

###### => Step 1 ###############################################################
echo_step "Step 1 -> Checking archiso version..."; echo

if [[ $archisoVersion == "$archisoRequiredVersion" ]]; then
  echo_step_info "Required archiso version: ${archisoRequiredVersion}"
	echo_success
else
  echo_step_info "Required archiso version: ${archisoRequiredVersion}"
	echo_failure
  echo_step_info "Installed archiso version: ${archisoVersion}"; echo
  exit_with_message "You need to install the correct version of Archiso, 'sudo downgrade archiso' or update the system."
fi

echo_step_info "Save archiso version to archiso.md"
sudo sed -i "s/\(^archiso-version=\).*/\1${archisoRequiredVersion}/" archiso.md
echo_success

echo_step_info "Make mkarchiso verbose"
sudo sed -i 's/quiet="y"/quiet="n"/g' /usr/bin/mkarchiso
echo_success
echo

###### => Step 2 ###############################################################
echo_step "Step 2 -> Setup the build folder"; echo
echo_step_info "Build folder : ${buildFolder}"; echo_success
echo_step_info "Out folder : ${outFolder}"; echo_success
echo_step_info "Delete any previous build folder"
[[ -d $buildFolder ]] && sudo rm -rf "$buildFolder"
echo_success

echo_step_info "Copy the archiso folder to the build folder"
mkdir "$buildFolder"
cp -r archiso "${buildFolder}/archiso"; echo_success
echo

###### => Step 3 ###############################################################
echo_step "Step 3 -> Setup the skel folder"; echo
copy_dotfiles
echo

if [[ $1 == "--clear" ]]; then
  echo_step "Extra Step -> Clear packman cache"
  yes | sudo pacman -Scc
  echo_success
  echo
fi

###### => Step 4 ###############################################################
echo_step "Step 4 -> Building the ISO - be patient"; echo
[[ -d $outFolder ]] || mkdir "$outFolder"
cd "${buildFolder}/archiso/" || exit 1

sudo mkarchiso -v -w "$buildFolder" -o "$outFolder" "${buildFolder}/archiso/"
echo_step_info "ISO build"; echo_success

echo_step_info "Copying pkglist"
isolabel=archonlinux-$(date +%Y.%m.%d)-x86_64
cp "${buildFolder}/iso/arch/pkglist.x86_64.txt"  "${outFolder}/${isolabel}-pkglist.txt"
echo_success
cd "$outFolder"
isolabel="${isolabel}.iso"
echo_step_info "Building sha1sum"; echo
sha1sum "$isolabel" | tee "$isolabel".sha1
echo_success
echo_step_info "Building sha256sum"; echo
sha256sum "$isolabel" | tee "$isolabel".sha256
echo_success
echo_step_info "Building md5sum"; echo
md5sum "$isolabel" | tee "$isolabel".md5
echo_success
echo

###### => Step 5 ###############################################################
echo_step "Step 5 -> Cleanup"; echo
sudo rm -rf "$buildFolder"
echo_success
echo

echo_title "Check your out folder : ${outFolder}"; echo

exit 0
