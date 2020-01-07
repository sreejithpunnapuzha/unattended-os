#!/usr/bin/env bash
set -o errexit
set -o xtrace
set +x
BLDIR=$(pwd)
ISO_PATH=$BLDIR/images
ISO_NAME=CentOS-7-Server-Unattended.iso
ISOFILES=$BLDIR/iso_tmp/isofiles
COPYFILES=$BLDIR/isofiles

echo "============================================================"
echo "Prebuilt setup"
echo "============================================================"

yum -y install wget rsync yum-utils createrepo genisoimage isomd5sum

if [[ ! -e $ISO_PATH ]]; then
   mkdir $ISO_PATH
else
   echo "iso directory already present continuing with iso generation"
fi

mkdir iso_tmp
cd iso_tmp || { echo "Cannot cd into build directory" ; exit 1 ; }
mkdir loopdir isofiles workspace

echo "============================================================"
echo "Downloading base ISO"
echo "============================================================"

ISO_URL='http://mirror.mobap.edu/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso'
ISO_FILE='CentOS-7-x86_64-Minimal-1908.iso'
test -f "$(basename $ISO_URL)" || wget -nv -c ${ISO_URL} -O $ISO_PATH/${ISO_FILE} || exit 1

echo "Download Completed"
echo "============================================================"
echo "Unpack ISO"
echo "============================================================"
sudo mount -o loop $ISO_PATH/${ISO_FILE} loopdir
rsync -a -H --exclude=TRANS.TBL loopdir/ isofiles/
sudo umount loopdir
chmod -R u+w isofiles

#cd isofiles/Packages
#yumdownloader --resolve tzdata ca-certificates vim wget deltarpm git
#   (cd isofiles/Packages ; yumdownloader $(for i in *; { echo ${i%%-[0-9]*}; } ) )

cd $ISOFILES/repodata
mv ./*minimal-x86_64-comps.xml comps.xml && {
ls | grep -v comps.xml | xargs rm -rf
}

cd $ISOFILES
discinfo=$(head -1 .discinfo)
createrepo -g repodata/comps.xml $ISOFILES

echo "============================================================"
echo "Adding configuration files to base ISO"
echo "============================================================"
cp $COPYFILES/kickstart/ks.cfg ks.cfg
yes | cp $COPYFILES/isolinux/isolinux.cfg isolinux/isolinux.cfg
#cp -r $COPYFILES/stuffs/ .

echo "================================================================"
echo "Generating ISO image"
echo "================================================================"
cd $ISOFILES
mkisofs -r -R -J -T -v -no-emul-boot -boot-load-size 4 -boot-info-table -V "CentOS 7 x86_64" -b isolinux/isolinux.bin -c isolinux/boot.cat -x "lost+found" --joliet-long -o $ISO_PATH/$ISO_NAME .

implantisomd5 $ISO_PATH/$ISO_NAME

echo "================================================================"
echo "Starting Cleanup"
echo "================================================================"
cd $BLDIR
rm -rf iso_tmp

echo "Unattended ISO generation and Cleanup completed"
