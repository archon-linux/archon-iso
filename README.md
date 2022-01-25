WIP:
- Archon Linux has been tested from github repositories and in a virtual machine as of this commit.
- Will update when I install on my hardware.

# Archon Linux ISO<a name="top"></a>
1. [Why?](#why)
2. [Building the ISO](#build)
3. [How?](#how)
4. [Archon core packages](#core)
5. [Archon dotfiles](#dotfiles)
6. [Manual and tricks](#manual)
7. [Archon Linux packages list](#packages)
8. [TODO / Need help](#todo)
9. [Update archiso](#update)

**TL/DR:**
- clone this repository.
- run `./build.sh`
- install system with the iso. btrfs and no swap are your only automated options. zram is used on real hardware installs.
- run all tasks at first reboot and relog when done.
- `Super + /` to show hotkeys, it's also the `?` key, rip non-qwerty...

## 1. Why?<a name="why"></a>

I figured might as well buid an ISO rather than have install scripts into dotfiles, and maybe learn a thing or two along the way.

[ALCI](https://github.com/arch-linux-calamares-installer) has been my goto to start figuring this out, and I highly suggest checking out all of the arcolinux projects.

So do not look at Archon Linux as a distribution, but more of a vanilla arch install with my default settings and configs to have a sane graphical environment. Most configs are heavily commented and can represent a solid starting base for any user.

This readme will be a sort of logbook of my progress, choices and fails as I build my dream *vanilla* arch linux!
## 2. Building the ISO<a name="build"></a>

I made it so `/etc/skel` for the Archon Linux ISO is a basic dotfiles system, handled by a bare git repository.

A bare repository dissociates the git directory from the working tree, allowing a pretty seamless integration. Here is a good [article](https://www.atlassian.com/git/tutorials/dotfiles) about such a setup.

Run `./build.sh` inside of the `archon-iso` folder to build your first ISO.

If it is your first run the build will run `get_dotfiles.sh` to setup the git bare repository and clone [archon-dotfiles](https://github.com/archon-linux/archon-dotfiles).

`./build.sh --clear` will clear the pacman cache and download the latest packages. Build with this flag after any sort of update on your build system.

If you plan to use Archon Linux as your daily driver, which you really should not so far, best would be to use the [archon-dotfiles](https://github.com/archon-linux/archon-dotfiles) repository as a template on github, not a fork, as you want to be able to make it private.

Now edit `get_dotfiles.sh` to match your repository `git_url` at the top of the file. Delete the current `dotfiles` directory if you already built once and run `./build.sh` again. You may also want to use your local repository folder when developing, check the comments in `archiso/pacman.conf`

More information in the #[dotfiles](#dotfiles) section.

The iso will be over 2Gb as the installer will not download anything so the install can be done fully offline.
## 3. How?<a name="how"></a>

Here are the main ways to modify the `airootfs` folder:

* Add changes directly into the folder. The most straightforward way to go about it. The drawback is that if you do everything that way it gets harder to compare your current `airootfs` with the vanilla archiso from `/usr/share/archiso/configs/releng`. You might also want a more UNIX way to go about it and just keep a clean `airootfs` while using external packages to bring in your changes.

* Using the iso `./build.sh` script add changes inside of the temp folder before the iso gets built. That's when we copy over the dotfiles into the skel folder.

* Using custom packages along with a custom repository. This should be the preferred way but it comes with its problems as well, mainly conflicts with default config files.

List of changes made directly to the `airootfs` folder, This is also roughly what [ALCI](https://github.com/arch-linux-calamares-installer) does to make it's base images:

1. Add a `liveuser` user for the live boot.

    Add:
    - `airootfs/etc/group`
    - `airootfs/etc/gshadow`
    - `airootfs/etc/polkit-1`
    - `airootfs/etc/systemd/journald.conf`
    - `airootfs/etc/systemd/logind.conf`
    - `airootfs/etc/sudoers.d/g_wheel`

    Edit:
    - `airootfs/etc/passwd`
    - `airootfs/etc/shadow`


2. Change our linux kernel to the `linux-zen` version and the iso branding.

    - Replace `airootfs/etc/mkinitcpio.d/linux.preset` by `airootfs/etc/mkinitcpio.d/linux-zen.preset`
    - Edit `airootfs/etc/mkinitcpio.conf`.
    - Edit all entries in `efiboot/loader/entries` and `syslinux` according to our new kernel and system name. These folders are in the `archiso` folder.
    - Edit `profiledef.sh` for iso branding.
    - Edit `packages.x86_64` with our added packages.
    - Edit `pacman.conf` to add our custom repository and others such as `chaotic-aur` for build time.


3. Add `airootfs/etc/systemd/system/default.target` that symlinks to `/usr/lib/systemd/system/graphical.target` since we want a graphical environment for calamares on iso boot.

    Also add `airootfs/etc/systemd/system/display-manager.service` that symlinks to our display manager `/usr/lib/systemd/system/lightdm.service`.


4. Replace systemd network services by `networkmanager`.

    Remove:
    - `airootfs/etc/systemd/system/dbus-org.freedesktop.network1.service`
    - `airootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service`
    - `airootfs/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service`.

    Add:
    - `airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service` that symlinks to `/usr/lib/systemd/system/NetworkManager-dispatcher.service`
    - `airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service` that symlinks to `/usr/lib/systemd/system/NetworkManager-wait-online.service`


I know this all does not look so minimal, but remember we only added a new user, switched the kernel to `linuz-zen` with iso branding, made sure we would have a display manager with a graphical session and moved from systemd networking to `networkmanager`. Small stuff compared to whats ahead!

These changes happened in the first few commits of this repository if you want to check more details.

Now comes in the custome packages to finish setting up the system.

## 4. Archon core packages<a name="core"></a>

How the base system is further customized. Check the [archon-core](https://github.com/archon-linux/archon-core) repository for more details on how I tried different ways to get things done. This is an interesting read if you plan on doing your own customized iso.

## 5. Archon dotfiles (aka default home directory)<a name="dotfiles"></a>
### dotfiles
As mentioned in the [Building the ISO](#build) section you should be forking the [archon-dotfiles](https://github.com/archon-linux/archon-dotfiles) repository. I suggest using the `get_dotfiles.sh` to clone your dotfiles repository locally inside of this repository folder, it will be ignored by the `.gitignore` life.

Make sure you add the `archondots` alias offered by the script to manage your dotfiles changes. Simply replace `git` by `archondots` in all of your commands.

Then push your changes to your fork to save them. For example one of the first thing I would add is my `.gitconfig`.

The iso is built with the local files, it does not pull from the repository before each build.

This is as good as any a place to lay out the use of the various profile files:

* `.bash_profile` has things that could either be in `.profile` or `.bashrc`, so we just don't have one.
* `.bashrc` is run for every bash shell we start, it is meant to setup aliases and other shell options. Ours is used to load the `pywal` colorscheme that would not work in `fish` and then start `fish`. `config.fish` then takes over and sets up aliases and various functions.
* `.inputrc` has some hidden jutsu such as ignore case for completion and other things. Found a reddit post about it suggesting some settings.
* `.profile` is basically like `.bash_profile` but gets run for any bourne shell, not just bash. This is where I set all of my environment variables by sourcing all `*.conf` files located in `~/.config/environment.d`.
* `.xprofile` has all of our startup applications to help support the window manager. Keeping the window manager's autostart mechanism for applications specific to it.

### ansible

Until you run one task, at each login  the `archon` script will autostart. It will offer to run a few diffetrent tasks, **run them all**, the option to select them one by one is just to help debug, or to run a single task after you made changes.

Remember that unlike a bash script, an ansible task, if properly setup, can run more than once and will only make changes when needed. It is idempotent!

You might have noticed that there is another playbook in `.ansible/playbooks` called `vault` in your `dotfiles`. This in charge of setting up everything that has some sort of secrets you need to absolutely keep private but still want versioned in your dotfiles for simplicty.

Ansible has a vault system that can encrypt a file with reasonably strong encryption. Make sur you use a long (32+) passphrase. This can be seen as a security issue to some but having your dotfiles in a private repo and have the sensitive data in an ansible encrypted vault should be safe enough...

Check the `.ansible/playbooks/vault/vault.yml.example` file. Now you understand how critical it is to keep this vault secure with a strong password, it contains your gpg and ssh private keys! Now these two keys should also have different strong passwords.

Of course it is up to you to use this, the `archon` script will not run the vault playbook if it can not find a `vault.yml` file.

Once edited properly, encrypt it using `ansible-vault encrypt .ansible/playbooks/vault/vault.yml`. You can edit it later with `ansible-vault edit .ansible/playbooks/vault/vault.yml`, warning it opens it in `vi`. Or simply decrypt it for easy editing: `ansible-vault decrypt .ansible/playbooks/vault/vault.yml`, don't forget to encrypt it again once done.

What the `vault` playbook does:
    - Set the environment variable values for openweathermap api, requires a relog.
    - Import your password store gpg key.
    - Import your github gpg signing key.
    - Import your ssh key.
    - Adds the ssh key to the agent and clones your `pass` password store from a private repository.

You can add more secrets in that file and modify/add roles to `.ansible/playbooks/vault/playbook.yml`.

The same can be done with `.ansible/playbooks/archon/playbook.yml` and the `.local/bin/archon` bash script.

I plan on keeping the Archon Linux project up to date with major changes I would make, but things I feel are personal tweaks I will add to my own version of those playbooks in my private dotfiles and so should you.

When ever you change something that would not be tracked by your dotfiles or can not be part of the iso you should add it as an `ansible` task as well. This way you will always have an iso that brings you right back to where you are.

## 6. Manual and tricks<a name="usage"></a>
wip....
### polybar
Don't hesitate to left click and right click things, most do something.
### no file manager needed
Using `zoxide` and some smart fish aliases and functions you really don't need a file manager anymore, gui or cli.

First `cd` is aliased to `z`. This means any time you cd into a folder it remembers it's path and you can now cd to that path using a fraction of it's name. If more than one path matches it offers a list to choose from.

For example:
```
~
❯ cd .config/fish/functions

.config/fish/functions via 🐍 v3.10.1
❯ cd

~
❯ cd fun

.config/fish/functions via 🐍 v3.10.1
❯
```

Now we can also replace the initial `cd .config/fish/functions` using fuzzy find.

`fcd` and hit enter, you can now fuzzy type to find the directory.

You can do the same with `open` that will use `xdg-open` on the file you pick, so be sure to set your mimetypes properly. We got `lxsession` for that but I haven't configured that *yet*.
## 7. Archon Linux packages list<a name="packages"></a>

Many choices, a single opinion.

I tried explaining what some more obscure packages did, if you have any questions about a package choice, please submit a new issue so I know to add information about it.
#### ***Changes to releng***
Removed
```
linux
virtualbox-guest-utils-nox
```
#### ***Kernel***
```
base-devel
linux-zen
linux-zen-headers
```
#### ***Archon***
```
archon-grub-theme
archon-gtk3-themes
archon-system
archon-wallpapers
```
#### ***Networking & internet***
```
brave
dnsutils
inetutils
networkmanager
network-manager-applet
ntp
wget
```
#### ***Repositories***
```
chaotic-keyring
chaotic-mirrorlist
```
#### ***Virtual machines***
```
spice-vdagent
virtualbox-guest-utils
```
#### ***Display manager***
```
lightdm
lightdm-slick-greeter
```
#### ***Calamares***
```
calamares
calamares-config
```
#### ***Grub & btrfs***
```
grub-btrfs
os-prober
snapper
snapper-gui-git
```
#### ***GPU drivers***
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
#### ***Xorg***
```
xorg-server     => Most other xorg packages are installed as dependencies.
xorg-xrdb       => For loading .Xresources, but most wm do it, not sure how needed it is yet...
xorg-xev        => Dependency to get keypress codes
xorg-xwininfo   => Is used by polybar scripts to display opened window names.
xorg-xinput     => Next two are for inputs such as mouse and touchpads.
xf86-input-libinput
```
#### ***X compositer***
```
picom-ibhagwan-git
```
Many `picom` forks, seems this one had all I needed. Grabbed my config from [DT dotfiles](https://gitlab.com/dwt1/dotfiles) and made a couple changes.
#### ***Terminals & related***
```
alacritty
bash-completion
dash
dashbinsh
fish
lolcat
neofetch
shell-color-scripts
sl
starship
tty-clock-git
xterm
```
`xterm` is still here as a fallback but alacritty is our default. Setting it as the `TERMINAL` environment variable seems to do the trick.

As mentioned `fish` is our shell using `starship` for the prompt and `lolcat` and `sl` for the memes, of course.

We also link `/bin/sh` to `dash`, a proper POSIX compliant shell, instead of `bash`, what a silly thing to do in the first place...

Rest is mostly lulz and memes.
#### ***General utilities***
```
ansible
arandr
browserpass
browserpass-chromium
dateutils
dconf-editor
dialog
expac
expect
fzf
git
gnupg
gparted
imagemagick
jq
pass
ripasso-cursive
logrotate
make
moreutils
p7zip
qrencode
rsync
scrot
shellcheck
sxiv
unclutter
unrar
unzip
virtualfish
xarchiver
xclip
xsettingsd
zbar
zip
zramd
```
Most of those are very standard and some are dependencies of scripts we will be running.

`ripasso-cursive` is a great terminal based `pass` manager. You will need to have a properly setup `.gitconfig`. Run `ripasso-cursive` to get help on how to properly set it up. `rofi-pass` (`super + p`) works with no configuration. Both require `pass` to be properly setup. Check the #[dotfiles](#dotfiles) section for how to get it setup with `ansible`.

`scrot` dependency for powermenu

`zramd` is just a painless way to deal with swap so I wanted to give it a shot.

`xarchiver` is a great lightweight archive GTK3 gui, always good to have the option.

I can make a note of `qrencode` and `zbar` that I use along with a script `asc2gif.sh` to make qrcodes out of gpg and ssh keys. You can find that script in `~/.config/gnupg`.

`pass` is the password manager system, you should really be using this...

`virtualfish` is an awesome wrapper for fish to hangle python virtual environments, amazing!
#### ***Rust utilities***
```
bandwhich
bat
dust
exa
fd
procs
ripgrep
sd
tealdeer
zoxide
```
I had been using a couple of those but discovered mor with this [article](https://zaiste.net/posts/shell-commands-rust/). Some of those are amazing such as `zoxide` and `tealdeer` and should become parts of your workflow, `cd` is aliased to zoxide in the fish config.

`bat` should replace your `cat` when using the terminal. Again, a really cool little utility.
#### ***LXDE***
```
lxappearance-gtk3
lxinput-gtk3
lxrandr-gtk3
lxsession-gtk3
```
We already covered `lxsession` but note that you want it started before the window manager, so `.xprofile` is again a good match for such autostart.

The other apps are just nice gui for setting gtk themes, input settings and display size.
#### ***XDG utilities***
```
xdg-utils
xdg-user-dirs
xdg-user-dirs-gtk
```
`xdg-user-dirs` with a custom configuration set by `~/.config/user-dirs.dirs` will ensure we have the proper base folders such as desktop, documents, downloads, etc... We also have a slew of environment variables for XDG set by `.profile`. We also install the `xdg-user-dirs-gtk` package, it sets the GTK bookmark file (the file manager bookmarks).

Check [XDG_Base_Directory#Support](https://wiki.archlinux.org/title/XDG_Base_Directory#Support) for more information on what application has an XDG config path option.
#### ***Libs & extras***
```
gnome-themes-extra
gtk-engine-murrine      => Both are missing libs some gtk apps complained about.
perl-file-desktopentry  => gives locale support to `obmenu-generator`.
python-pexpect          => dependency of `ansible`.
python-pillow
python-numpy            => both are dependencies for a script to generate png.
qt5-x11extras           => dependency of `zbar` (qrcode script).
```
#### ***Openbox***
```
obconf
obkey
obmenu-generator
obmenu2-git
openbox
```
I am planning for more window managers such as maybe `herbstluftwm` or `xmonad` later on but really like the flexibility of `openbox`.

I honestly use only `obmenu-generator` for it's dynamic pipe but figured having the gui configuration apps could not hurt (theme, hotkeys and menu editing).

`openbox` also has a global environment file but I am not using it as I dont need anything `openbox` specific.
#### ***File manager***
```
nemo
```
I use the terminal to navigate files and am not a fan of terminal based file managers. It is nice to have a fallback gui for certain things so here comes `nemo`, it does what it needs to do.
#### ***Text editors***
```
neovim
vscodium
vi
```
Sometimes things open by default in `vi` and it's easier to have it than hunt around for how to change the default editor for that one thing or mess with environment variables.

`neovim`, maybe just because haha I rarely use vim and figured if I start getting into it I'll go for `neovim`.

`vscodium`, it's my main IDE, I try to make all the references to it using the alias `code` so if you change the alias for it in `~/config/fish/config.fish` everything should mostly open with your editor of choice.
#### ***System monitors***
```
bottom-git
glances
htop
lsof
progress
strace
sysstat
```
`bottom` is a very nice terminal system monitor, might drop `glances` and `htop` (`lsof` and `strace` both being optional dependencies for `htop`). `systat` is just a collection of perf monitoring tools.

`progress` allows for checking on the progress of coreutils basic commands (cp, mv, dd, tar, gzip/gunzip, cat, etc.) that might take a long time. Check the [github](https://github.com/Xfennec/progress) for examples.
#### ***Package manager***
```
pacman-contrib
pamac-aur
paru
```
`paru` is just great, feels like a drop in replacement for pacman without the silly sudo. I am keeping a GUI for it right now and `pamac` does a great job at it. If I can get a packgage update notification I like with polybar, pamac is also nice on the command line but teaches bad habits as you don't need to use proper pacman flags.
#### ***Bluetooth***
```
blueman
bluez
bluez-utils
pulseaudio-bluetooth
```
#### ***Audio***

```
alsa-tools
alsa-utils
pavucontrol
pulseaudio-alsa
pulseaudio-equalizer-ladspa
```
Pretty straightforward `pulseaudio` setup, the 15 band equalizer is nice.
#### ***Core wm utilities***
```
betterlockscreen
dunst
feh
polybar
rofi
rofi-calc
rofi-pass-git
slop
sxhkd
wmctrl
```
Pretty standard selection, I'd rather use `sxhkd` for my hotkeys so it can be cross window manager. `wmctrl` and `slop` are for `rofi` scripts.
#### ***Themes***
```
flavours
papirus-icon-theme-git
```
[flavours](https://github.com/misterio77/flavours) is what the scripts use to manage [base16](https://github.com/chriskempson/base16) color schemes.
#### ***Fonts***
```
adobe-source-code-pro-fonts
font-manager
nerd-fonts-fira-code
ttf-dejavu
ttf-liberation
```
Some are just defaults, `nerd-fonts-fira-code` being the main font, much of a wip, didn't really spend more than 10 seconds on it...

## 8. TODO / Need help<a name="todo"></a>

Thats where I jot down stuff that I plan to work on or bother me...

`lxsession` comes with `xsettings-daemon` but I cant get it started as it asks for a config file and I cant find an exemple anywhere. Using `xsettingsd` for that job for now. I also need to figure out what `lxsettings` exactly does, and how it should or not be started by `lightdm` instead of it's default session thing? Me still confused haha...Or replace `lxsettings` by another polkit and dex to autostart .desktop files, not sure what I would be loosing from `lxsession` by doing that? Again, confused, rambling...

Finish customizing calamares with nice icons and graphics, also a custom neofetch could be nice.

## 9. Update archiso<a name="update"></a>

First commit will have the archiso folder be a copy of the archiso 60-1 releng folder. Compare this commit with the latest releng folder when updating archiso version.

`git checkout 'git rev-list --max-parents=0 HEAD | tail -n 1'`
`diff -rq ./archiso /usr/share/archiso/configs/releng`

Change the archiso version in `archiso.md` and `./build.sh`.

## Sources / Inspiration

The main starting point for this project was https://github.com/arch-linux-calamares-installer along with many scripts and concepts from https://github.com/archcraft-os/
