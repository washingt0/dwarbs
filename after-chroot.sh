#! /bin/sh

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

read -p 'Enter the hostname: ' INSTALL_HOST
echo $INSTALL_HOST >> /etc/hostname

echo 'Gerenating local hosts'
echo -e "127.0.0.1\t\tlocalhost\n::1\t\t\t\tlocalhost\n127.0.0.1\t\t$INSTALL_HOST\n" >> /etc/hosts

echo 'Generating initramfs'
mkinitcpio -p linux

echo 'Setting root password'
passwd

# User creatiion
read -p "Enter the username: " username
useradd -m $username
echo "Creating password for $username"
passwd $username
echo '%sudoers    ALL=(ALL) ALL' >> /etc/sudoers
groupadd sudoers
gpasswd -a $username sudoers

echo 'Lets pray'
echo 'Installing GRUB and efibootmgr'
pacman -S grub efibootmgr

echo 'Installing GRUB to disk'
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck

echo 'Generating GRUB settings'
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Enabling multilib'
sed -i '/^#\[multilib\]$/ {N; s/#\[multilib\]\n#/\[multilib\]\n/}' /etc/pacman.conf
pacman -Sy

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
pacman -S sudo zsh xfce4-terminal thunar firefox gvfs tumbler thunar-volman thunar-archive-plugin unzip xfce4-goodies keepassxc mopidy sshfs openssh vlc smbclient redshift python-xdg python-pip gvfs-smb gvfs-nfs gpa zip xarchiver
systemctl enable systemd-timesyncd

echo 'Installing devs'
pacman -S git vim neovim-qt xfce4-settings htop strace lsof xfce4-power-manager cantarell-fonts noto-fonts gnu-free-fonts powerline-fonts awesome-terminal-fonts python-pywal go go-tools godep xsel guake ranger mc ttf-ubuntu-font-family

echo 'Setting defaults'
echo 'Default shell'
chsh -s /bin/zsh

echo 'Installing polybar'
echo 'Installing dependencies for polybar'
pacman -S cairo xcb-util-cursor xcb-util-image xcb-util-wm xcb-util-xrm cmake git pkg-config python python2 alsa-lib curl jsoncpp libmpdclient libnl pulseaudio wireless_tools xorg-fonts-misc gcc clang python-sphinx xcb-proto libxcb libpulse libcurl-compat libcurl-gnutls fakeroot xorg-xfd
echo 'Installing fonts from AUR'
sudo -u $username bash<<_
cd /tmp
git clone https://aur.archlinux.org/siji-git.git
cd siji-git
makepkg -si --skippgpcheck
Y
cd ..
git clone https://aur.archlinux.org/ttf-unifont.git
cd ttf-unifont
makepkg -si --skippgpcheck
Y
cd ..
chsh -s /bin/zsh
_
git clone https://github.com/polybar/polybar --recursive
cd polybar
mkdir build
cd build
cmake ..
make -j$(nproc)
make install
cd ..

git clone https://github.com/stark/siji
cd siji
./install.sh

# Fonts
xset +fp /home/$USER/.local/share/fonts
xset fp rehash

# Install vim-plug
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
