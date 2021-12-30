#!/bin/bash
#set -e
##################################################################################################################
# Author	:	Erik Dubois
# Website	:	https://www.erikdubois.online
# Website	:	https://www.arcolinux.info
# Website	:	https://www.arcolinux.com
# Website	:	https://www.arcolinuxd.com
# Website	:	https://www.arcolinuxb.com
# Website	:	https://www.arcolinuxiso.com
# Website	:	https://www.arcolinuxforum.com
# Website	:	https://www.alci.online
##################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################
echo
echo "################################################################## "
tput setaf 2
echo "Phase 1 : "
echo "- Setting General parameters"
tput sgr0
echo "################################################################## "
echo

	# setting of the general parameters
	archisoRequiredVersion="archiso 60-1"
	buildFolder=$HOME"/archon-build"
	outFolder=$HOME"/archon-iso-out"
	archisoVersion=$(sudo pacman -Q archiso)

	echo "################################################################## "
	echo "Do you have the right archiso version? : $archisoVersion"
	echo "What is the required archiso version?  : $archisoRequiredVersion"
	echo "Build folder                           : $buildFolder"
	echo "Out folder                             : $outFolder"
	echo "################################################################## "
	echo
	if [ "$archisoVersion" == "$archisoRequiredVersion" ]; then
		tput setaf 2
		echo "##################################################################"
		echo "Archiso has the correct version. Continuing ..."
		echo "##################################################################"
		tput sgr0
	else
	tput setaf 1
	echo "###################################################################################################"
	echo "You need to install the correct version of Archiso"
	echo "Use 'sudo downgrade archiso' to do that"
	echo "or update your system"
	echo "If a new archiso package comes in and you want to test if you can still build"
	echo "the iso then change the version in line 37."
	echo "###################################################################################################"
	tput sgr0
	fi

echo
echo "################################################################## "
tput setaf 2
echo "Phase 2 :"
echo "- Checking if archiso is installed"
echo "- Saving current archiso version to archiso.md"
echo "- Making mkarchiso verbose"
tput sgr0
echo "################################################################## "
echo

	package="archiso"

	#----------------------------------------------------------------------------------

	#checking if application is already installed or else install with aur helpers
	if pacman -Qi $package &> /dev/null; then

			echo "Archiso is already installed"

	else

		#checking which helper is installed
		if pacman -Qi yay &> /dev/null; then

			echo "################################################################"
			echo "######### Installing with yay"
			echo "################################################################"
			yay -S --noconfirm $package

		elif pacman -Qi trizen &> /dev/null; then

			echo "################################################################"
			echo "######### Installing with trizen"
			echo "################################################################"
			trizen -S --noconfirm --needed --noedit $package

		fi

		# Just checking if installation was successful
		if pacman -Qi $package &> /dev/null; then

			echo "################################################################"
			echo "#########  $package has been installed"
			echo "################################################################"

		else

			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "!!!!!!!!!  $package has NOT been installed"
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			exit 1
		fi

	fi

	echo
	echo "Saving current archiso version to archiso.md"
	sudo sed -i "s/\(^archiso-version=\).*/\1$archisoVersion/" archiso.md
	echo
	echo "Making mkarchiso verbose"
	sudo sed -i 's/quiet="y"/quiet="n"/g' /usr/bin/mkarchiso

echo
echo "################################################################## "
tput setaf 2
echo "Phase 3 :"
echo "- Deleting the build folder if one exists"
echo "- Copying the Archiso folder to build folder"
tput sgr0
echo "################################################################## "
echo

	echo "Deleting the build folder if one exists - takes some time"
	[ -d "$buildFolder" ] && sudo rm -rf "$buildFolder"
	echo
	echo "Copying the Archiso folder to build work"
	echo
	mkdir "$buildFolder"
	cp -r archiso "${buildFolder}/archiso"

echo
echo "################################################################## "
tput setaf 2
echo "Phase 4 :"
echo "- Cleaning the cache from /var/cache/pacman/pkg/"
tput sgr0
echo "################################################################## "
echo

	if [[ $1 == "--clear" ]]; then
		echo "Cleaning the cache from /var/cache/pacman/pkg/"
		yes | sudo pacman -Scc
	else
		echo "Skipping"
	fi

echo
echo "################################################################## "
tput setaf 2
echo "Phase 5 :"
echo "- Building the iso - this can take a while - be patient"
tput sgr0
echo "################################################################## "
echo

	[ -d "$outFolder" ] || mkdir "$outFolder"
	cd "${buildFolder}/archiso/" || exit 1
	sudo mkarchiso -v -w "$buildFolder" -o "$outFolder" "${buildFolder}/archiso/"

 	echo "Moving pkglist.x86_64.txt"
 	echo "########################"
	rename=$(date +%Y-%m-%d)
 	cp "${buildFolder}/iso/arch/pkglist.x86_64.txt"  "${outFolder}/archon-linux-${rename}-pkglist.txt"

echo
echo "##################################################################"
tput setaf 2
echo "DONE"
echo "- Check your out folder : $outFolder"
tput sgr0
echo "################################################################## "
echo
