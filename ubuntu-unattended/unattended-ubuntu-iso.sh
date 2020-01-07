#!/usr/bin/env bash
set -o errexit
set -o xtrace
set +x
BLDIR=$(pwd)
ISO_VERSION=$1

sudo apt-get install -y --force-yes curl rsync genisoimage git

echo "============================================================"
echo "Downloading base ISO"
echo "============================================================"

if [[ ! -e iso ]]; then
   mkdir iso
else
   echo "iso directory already present continuing with iso generation"
fi

mkdir iso_tmp
cd iso_tmp
mkdir loopdir isofiles workspace

if [ $ISO_VERSION = "1404" ]; then
   echo "Using Ubuntu 14.04 Mirror"
   ISO_URL='http://releases.ubuntu.com/14.04/ubuntu-14.04.5-server-amd64.iso'
   ISO_FILE='ubuntu-14.04.5-server-amd64.iso'
elif [ $ISO_VERSION = "1604" ]; then
   echo "Using Ubuntu 16.04 Mirror"
   ISO_URL='http://releases.ubuntu.com/16.04/ubuntu-16.04.6-server-amd64.iso'
   ISO_FILE='ubuntu-16.04.6-server-amd64.iso'
else [ $ISO_VERSION = "1804" ]
   echo "Using Ubuntu 18.04 Mirror"
   ISO_URL='http://cdimage.ubuntu.com/releases/18.04.2/release/ubuntu-18.04.2-server-amd64.iso'
   ISO_FILE='ubuntu-18.04.2-server-amd64.iso'
fi

# get and unpack the ISO
wget -nv -c ${ISO_URL} -O ../iso/${ISO_FILE} || exit 1
sudo mount -o loop ../iso/${ISO_FILE} loopdir
rsync -a -H --exclude=TRANS.TBL loopdir/ isofiles/
sudo umount loopdir
chmod -R u+w isofiles


echo "============================================================"
echo "Adding configuration files to base ISO"
echo "============================================================"

# copy apollo parts to image root
cp ../isofiles/preseed/ubuntu-server-${ISO_VERSION}-unattended-iso.seed ../iso_tmp/isofiles/preseed/ubuntu-server-${ISO_VERSION}-unattended-iso.seed
cp ../isofiles/isolinux/isolinux-${ISO_VERSION}.cfg ../iso_tmp/isofiles/isolinux/isolinux.cfg
cp -r ../isofiles/stuffs/ ../iso_tmp/isofiles/
chmod -R u+w ../iso_tmp/isofiles/
cd ../iso_tmp/isofiles/
BLDIR=$(pwd)

echo "================================================================"
echo "Generating ISO image"
echo "================================================================"

pwd
md5sum $(find ! -name "md5sum.txt" ! -path "./isolinux/*" -follow -type f) > md5sum.txt
genisoimage -o ../../iso/ubuntu-${ISO_VERSION}-server-unattended.iso -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat .

echo "================================================================"
echo "Starting Cleanup"
echo "================================================================"

pwd
cd ../../
rm -rf iso_tmp

echo "Unattended ISO generation and Cleanup completed"
