#!/bin/bash

CDIMAGENAME='ubuntu-mate-16.04.2-desktop-amd64.iso'
IMAGE_NAME='Custom1604'

echo "Copying $CDIMAGENAME to working directory..."

cd ~/.
mkdir custom-img
cp $CDIMAGENAME custom-img
cd custom-img

# Extract the CD .iso contents

#Mount the .iso to a local mount point. 'loop' is a read-only device, so mount will
# warn that it is mounting it read-only. You can use "-o loop,ro" to avoid that warning, if you like.
mkdir mnt
echo "Mounting the .iso as 'mnt' in the local directory. Password-up, please."
sudo mount -o loop $CDIMAGENAME mnt

#Extract the .iso contents into dir 'extract-cd'
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

#Extract the isohybrid MBR 'isohdpfx.bin' from the source ISO image using dd
sudo dd if=$CDIMAGENAME bs=512 count=1 of=extract-cd/isolinux/isohdpfx.bin

# Extract the Desktop system
#Extract the SquashFS filesystem
sudo unsquashfs mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit

#We are finished with the source .iso image. Unmount it.
sudo umount mnt

#Delete the source .iso copy.
rm $CDIMAGENAME

# Prepare and chroot
sudo cp /etc/resolv.conf edit/etc/
sudo mount --bind /dev/ edit/dev

# Learned this inline scripting from https://askubuntu.com/questions/551195/scripting-chroot-how-to.
cat << EOF | sudo chroot edit
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

# "To avoid locale issues and in order to import GPG keys..."
export HOME=/root
export LC_ALL=C
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

#Customizations

# Add Google Chrome's stable repository to apt (hey, I like Chrome)
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -

#Update and Upgrade (distributions)
apt-get update
apt-get dist-upgrade -y

apt-get install google-chrome-stable -y
apt-get autoremove -y
apt-get autoclean -y

#Clean up
rm -rf /tmp/* ~/.bash_history
rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

# "now umount (unmount) special filesystems and exit chroot"
umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
EOF

sudo umount edit/dev

echo "Regenerate the manifest"

#Regenerate the manifest
sudo chmod +w extract-cd/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee extract-cd/casper/filesystem.manifest
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

#Compress the filesystem
# Delete any existing squashfs - normally nothing to delete/rm.
sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -b 1048576

#"Update the filesystem.size file, which is needed by the installer"
printf $(sudo du -sx --block-size=1 edit | cut -f1) | sudo tee extract-cd/casper/filesystem.size

#"Remove old md5sum.txt and calculate new md5 sums"
cd extract-cd
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

#"Create the ISO image"
#manpage for genisoimage http://manpages.ubuntu.com/manpages/trusty/man1/genisoimage.1.html
#original
#sudo genisoimage -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../$IMAGE_NAME.iso .

#from EFI Q&A: https://askubuntu.com/questions/457528/how-do-i-create-an-efi-bootable-iso-of-a-customized-version-of-ubuntu
#sudo mkisofs -U -A "Custom1604" -V "Custom1604" -volset "Custom1604" -J -joliet-long -r -v -T -o ../Custom1604.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot .

# From https://linuxconfig.org/legacy-bios-uefi-and-secureboot-ready-ubuntu-live-image-customization
# THIS WORKS for creating a .iso that can boot a PC from USB after dd to the USB drive, and as a file referenced as the boot image for a VM (e.g. VirtualBox)
sudo xorriso -as mkisofs -isohybrid-mbr isolinux/isohdpfx.bin -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -o ../$IMAGE_NAME.iso .

# Not necessary, but you can check that a bootable partition is visible to fdisk..
# If no bootable partiction is visible to fdisk, my experience is that the ISO will not boot from USB.
# If so, we should be good to go.
sudo fdisk -lu ../$IMAGE_NAME.iso
