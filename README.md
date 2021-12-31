WIP, local repo mode is set in `archiso/pacman.conf`
# Archon Linux ISO

## Why?

I figured might as well buid an ISO rather than have install scripts into dotfiles, and maybe learn a thing or two along the way.
This readme will be a sort of logbook of my progress, choices and fails as I build my dream OS!
## Building the ISO

Use the `build.sh` script, use `./build.sh --clear` to clear pacman cache and download latest packages after any sort of update on your build system.

### Snapshot branches

Checkout any of these branches to build a specific version of Archon Linux.
* `main`: The latest and greatest

* `minimal`: Branch from a commit that builds the minimal package list, a very barebones system with our repo, chaotic repo, `lightdm` and `openbox` setup on a `btrfs` partition with `snapper`, as described below.

## Packages

Many choices, a single opinion.

You can refer to the commit history to see how these changes were implemented from a vanilla archiso releng folder.

### Minimal package list to have a *workable* system after install

* The systemd network services were replaced by those from `networkmanager` and the related network utilities such as `network-manager-applet` and `inetutils` were added.

* From the vanilla releng package list `linux` and `virtualbox-guest-utils-nox` are replaced in favor of `linux-zen` and `virtualbox-guest-utils`, you can check the required changes to the files in the commit history.

* `liveuser` is created for the calamares graphical install session.

* `lightdm` and `lightdm-slick-greeter` configuration files are included in the archiso files as it's a pain to deal with the conflict from having them imported from packages at build time like we will for the skeleton files and other configs. The lightdm wallpaper will be imported from the `archon-theme` package.

* Add the Archon Linux repository to `archiso/pacman.conf` which will make `chaotic-keyring` and `chaotic-mirrorlist` available along with all our other custom packages. Note there is a local option for the `archon-repo` for development.

* At that point very little changes should be happening in the archiso folder. Emphasis on should, I'll keep my commit history legit!

    We can now boot and have a live session along with all the packages we could need from our repository and chaotic. But not much will happen yet.

* So let's start by adding `calamares` and `calamares-config`. The latter is used to configure everything about our calamares install, most notably that we will be using the zen kernel and 'forcing' btrfs (one opinion, right?). Hopefully this whole essay will help you change such things to your opinion on the matter.

* Another key part of the Archon Linux calamares config package are the `post_install.sh` and `chrooted_post_install.sh` scripts. They are in charge of cleaning up and doing some prep work such as setting up the snapshot btrfs subvolume. Both files are well commented and offer a debug log to a file (`/var/log/{post_install.log,chrooted_post_install.log}`) that is available after the first reboot.

* This nicely leads us to our next section, note `os-prober` helping with dual booting:
    ```
    grub-btrfs
    os-prober
    snapper
    snapper-gui-git
    ```

* The post install scripts will also remove all unused graphics drivers, so might as well install all of them:
    ```
    nvidia
    nvidia-settings
    nvidia-utils
    xf86-video-amdgpu
    xf86-video-ati
    xf86-video-fbdev
    xf86-video-intel
    xf86-video-nouveau
    xf86-video-vesa
    ```

* Next we need the `xorg-server` along with `xorg-xinput` and `xf86-input-libinput` for support for mouse and touchpads in case the install is on a laptop (NOT optimized for laptops, yet).

* We will want to log the session into `openbox` as it is the main window manager for Archon Linux and let's add `xterm` as it is a default terminal for many window managers. Of course we also add `neofetch` for the rice.

* FInally we need a way to autostart the calamares installer which creates a desktop file in `/etc/xdg/autostart`. Looking at the wiki (https://wiki.archlinux.org/title/XDG_Autostart) we have a few choices. `dex` is a pretty standard one and most desktop environments have their own support for it. `openbox` can do it if the `python-pyxdg` package is installed.

    What is not mentioned is that `lxsession-gtk3`, that we plan to use as our session manager, also handles autostarting xdg applications. Problem solved right? Not just yet. We need to now autostart `lxsession`...

    Again, many choices. We know we want it to start running when Xorg starts or when the window manager starts. Let's plan for the future and put as little as possible in the window manager startup in case we want to change it or add another one. This leaves us with `.xinitrc` and `.xprofile`. Since `lightdm` uses `.xprofile` and not `.xinitrc` by default our choices are gone. This also sets us on a clear path to put all startup applications in `.xprofile` and be ready to run more window managers and desktop environments together in the future.

    Now we can choose how to include that `.xprofile` file in our iso. Simplest method is to simply add it to the archiso folder, but remember, we want out configs to come from custom built packages. For this branch commmit state we will put it in `archiso/etc/skel`.

## Development environment for the ISO

Clone all `archon-linux` repositories in the same folder, including this one.
Edit `archiso/pacman.conf` to set it up for a local repo.

## Maintaining the ISO

### Updating archiso

First commit will have the archiso folder be a copy of the archiso 60-1 releng folder. Compare this commit with the latest releng folder when updating archiso version.

`git checkout 'git rev-list --max-parents=0 HEAD | tail -n 1'`
`diff -rq ./archiso /usr/share/archiso/configs/releng`

Change the archiso version in `archiso.md` and the 2 install scripts.

## Sources / Inspiration

The main starting point for this project was https://github.com/arch-linux-calamares-installer along with many scripts and concepts from https://github.com/archcraft-os/

## Legacy ALCI readme this project is based from:

# ALCI DEVELOPMENT/DESKTOP

# Arch Linux Calamares Installer or ALCI

Use the correct version of Archiso to build the iso.

**Read the archiso.md.**

Download the content of the github with (use the terminal)

`git clone https://github.com/arch-linux-calamares-installer/alci-iso-zen`

# Pacman.conf in archiso folder

Only the archiso/pacman.conf will be used to download your packages.

You can activate more sources besides Arch Linux repos

    arcolinux
    chaotic
    your own local repo



# Pacman.conf in archiso/airootfs/etc/

This will be your future system. 
Include the repositories you want.
It will not be used to build the iso.


# Keys and Mirrors

## ArcoLinux keys and mirror

Add the ArcoLinux keys and Arcolinux mirrors to the packages.x86_64.
The pacman-init service  at etc/systemd/system/pacman-init.service will add any keys present.


## Chaotic keys and mirror

Add the Chaotic keys and Chaotic mirrors to the packages.x86_64.
The pacman-init service  at etc/systemd/system/pacman-init.service will add any keys present.


# Archiso/packages.x86_64

Only the archiso/packages.x86-64 files will be used.

Add more packages at the bottom of the file

If you plan to use ArcoLinux packages

* arcolinux-keyring

* arcolinux-mirror

If you plan to use Chaotic packages

* chaotic-keyring

* chaotic-mirrorlist

You can even add packages from your own personal local repo.


If you know you are going to need drivers for graphical cards or NICs put them on the iso.
I am thinking about xf86-video-intel, nvidia or other drivers.

# Build process

Install these two packages on your system if you want to include **Chaotic packages** on the iso

`sudo pacman -S chaotic-mirrorlist chaotic-keyring`

If not on ArcoLinux you can install them from AUR.


Install these two packages on your system if you want to include **ArcoLinux packages** on the iso

`sudo pacman -S arcolinux-mirrorlist-git arcolinux-keyring`

If not on ArcoLinux you can download the package from the alci_repo with sudo pacman -U.

https://github.com/arch-linux-calamares-installer/alci_repo


After editing the necessary files (pacman.conf and packages.x86_64) you can start building.

Use the scripts from this folder:

<b>installation-scripts</b>

Use script 30 and it will clean your pacman cache and redownload every package it needs.

Use script 40 to use your current pacman cache - it will only download what is needed.

You will find the iso in this folder:

 ~/Alci-Iso-Zen-Out

Burn it with etcher or other tools and use it.

Still not sure what to do.

Check out the playlist on Youtube

https://www.youtube.com/playlist?list=PLlloYVGq5pS4vhYQuLikS8dhDjk6xaiXH


# Installation process

Is documented on 

https://www.alci.online


# After installation

We have added a script to activate your display manager by default.
If you reboot you will boot into a graphical environment.

If you did not install a desktop environment on the iso you can still do so by going to 
TTY and installing one. SDDM stays after installation.

If you install more than one display manager they will overrule each other. SDDM will always lose
to gdm, lightdm or lxdm.


If you are still in the terminal then activate the display manager of your choice manually.

`sudo systemctl enable gdm`

`sudo systemctl enable lightdm`

`sudo systemctl enable sddm`

`sudo systemctl enable lxdm`

Get the pacman databases in

`sudo pacman -Sy`

or update immediately

`sudo pacman -Syyu`


# Tip

Sometimes a "proc" folder stays mounted.

Unmount it with this

sudo umount /home/{username}/...  use the TAB


# Tip

We have added a /etc/pacman-more.conf file to your future system.
That way we have the ArcoLinux repos and Chaotic repos if we do decide to install it after all.
Remember to install the mirror and keys.


# Tip

Run into issues - remove all packages manually with

`sudo pacman -Scc`

and ensure they are all gone.


# Tip

When testing out the ALCI in virtualbox, you can use the alias 
evb to enable and start virtualbox. As a result you can use your full resolution.



# Tip

When using gdm as display manager remember to delete the file /archiso/airootfs/etc/motd from your system. That files comes originally from Arch Linux.
To avoid waiting for every login and this nice look.
https://imgur.com/a/EvCN4pm


# Tip

Internet is NOT required for ALCI. Calamares is only using the internet to check where you live to put the red dot correctly on the world map (geoip). Calamares will **not download anything**. 

The list you created in the packages.x86_64 file will be installed on the iso and on your future system.

On demand of our users we have added 3 links to the archiso folder so that in the live environment they will have network manager.

/archiso/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
/archiso/airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
/archiso/airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service

If you do not use Networkmanager, you can delete them. You can also keep them as they are pointing to services you have not installed. The links will have no effect at all.

Remember there is still **nmtui** if the gui Networkmanager fails you in some way.

If you did NOT install it on the iso. These are the steps you can still do.

`setxkbmap be  - I will set my keyboard to azerty`


`sudo pacman -Sy - get the pacman databases in`


`sudo pacman -S networkmanager - installing the software`


`sudo systemctl enable NetworkManager - mind the capital letters`


`sudo systemctl start NetworkManager`


`nmtui`

Then connect to the wifi.

Then we restart Calamares.

`sudo calamares`
