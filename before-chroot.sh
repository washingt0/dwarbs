#! /bin/sh

echo 'Setting keyboard layout'
loadkeys br-abnt2

echo 'Checking if EFI is available'
if [[ -d /sys/firmware/efi/efivars ]]
then
    echo 'EFI is enabled'
else
    echo 'BIOS is enabled'
fi

echo 'Enable NTP'
timedatectl set-ntp true

echo 'Partitions'
fdisk -l

echo 'Running pacstrap with base'
pacstrap /mnt base

echo 'Generating fstab'
genfstab -U /mnt >> /mnt/etc/fstab

echo 'Copying the second script /root in the new installation'
cp after-chroot.sh /mnt/root
chmod +x /mnt/root/after-chroot.sh

echo 'Changing root'
arch-chroot /mnt
