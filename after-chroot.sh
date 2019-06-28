#! /bin/sh

echo 'Make sure you have set:
    INSTALL_HOST -> hostname of installation
    DOTFILE_REPO -> GIT repository of dot files
'

read -p "Continue (y/n)? " choice
case "$choice" in
  y|Y ) echo "Ok, let's do this";;
  n|N ) exit 1;;
  * ) echo "invalid";;
esac

# TODO user creation

echo 'Setting time zone'
ln -sf /usr/share/zoneinfo/America/Fortaleza /etc/localtime

echo 'Ajusting hardware clock'
hwclock --systohc

echo 'Setting localization'
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen

echo 'Generating locale'
locale-gen

echo 'Setting language'
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf

echo 'Persisting keyboard layout'
echo 'KEYMAP=br-abnt2' >> /etc/vconsole.conf

echo 'Setting hostname from `INSTALL_HOST` environment variable'
echo $INSTALL_HOST >> /etc/hostname

echo 'Gerenating local hosts'
echo -e "127.0.0.1\t\tlocalhost\n::1\t\t\t\tlocalhost\n127.0.0.1\t\t$INSTALL_HOST\n" >> /etc/hosts

echo 'Generating initramfs'
mkinitcpio -p linux

echo 'Setting root password'
passwd

echo 'Lets pray'
echo 'Installing GRUB and efibootmgr'
pacman -S grub efibootmgr

echo 'Installing GRUB to disk'
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck

echo 'Generating GRUB settings'
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Enabling multilib'
sed -i '/^#\[multilib\]$/ {N; s/#\[multilib\]\n#/\[multilib\]\n/}' /etc/pacman.conf

echo 'Installing X-basic'
pacman -S xorg-server xorg-server-common xf86-video-intel mesa lib32-mesa lightdm lightdm-gtk-greeter accountsservice xorg-xrandr arandr compton xorg-xprop xorg-drivers

if lspci | grep --quiet NVIDIA
then
    echo 'Removing NOUVEAU driver and installing bumblebee'
    pacman -Rc xf86-video-nouveau
    pacman -S bumblebee mesa xf86-video-intel nvidia lib32-nvidia-utils lib32-virtualgl nvidia-settings bbswitch
    gpasswd -a $USER bumblebee
    gpasswd -a $USER video
    systemctl enable bumblebeed.service
fi

echo 'Enabling LightDM'
systemctl enable lightdm

echo 'Installing network-basic'
pacman -S networkmanager network-manager-applet networkmanager-openvpn  networkmanager-pptp dhclient

echo 'Enabling NetworkManager'
systemctl enable NetworkManager

echo 'Installing i3'
pacman -S i3-gaps i3lock i3status dmenu

echo 'Installing sound'
pacman -S alsa-lib alsa-plugins alsa-utils pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol

echo 'Installing misc'
pacman -S sudo zsh xfce4-terminal thunar firefox gvfs tumbler thunar-volman thunar-archive-plugin unzip xfce4-goodies

echo 'Installing devs'
pacman -S git vim neovim-qt

echo 'Setting defaults'
echo 'Default shell'
chsh -s /bin/zsh

echo 'Installing polybar'
echo 'Installing dependencies for polybar'
pacman -S cairo xcb-util-cursor xcb-util-image xcb-util-wm xcb-util-xrm cmake git pkg-config python python2 alsa-lib curl jsoncpp libmpdclient libnl pulseaudio wireless_tools xorg-fonts-misc gcc clang python-sphinx xcb-proto libxcb libpulse libcurl-compat libcurl-gnutls
echo 'Installing fonts from AUR'
# TODO
# git clone https://aur.archlinux.org/siji-git.git
# cd siji-git
# makepkg -si
# cd ..
# TODO
# git clone https://aur.archlinux.org/ttf-unifont.git
# cd ttf-unifont
# makepkg -si
# cd ..
git clone https://github.com/polybar/polybar --recursive
cd polybar
mkdir build
cd build
cmake ..
make -j$(nproc)
make install
cd ..

echo 'Getting dot files'
git clone $DOTFILE_REPO

