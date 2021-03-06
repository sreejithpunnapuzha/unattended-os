#!/bin/bash

function _debootstrap (){
  debootstrap \
    --arch=amd64 \
    --components=main,restricted,universe,multiverse \
    --variant=minbase \
    bionic \
    "${HOME}"/LIVE_BOOT/chroot \
    http://archive.ubuntu.com/ubuntu/
}

function _use_ubuntu_net_device_names (){
# this prioritizes the path policy over slot
# giving ubuntu compatible interface names
  cat <<EOF>"${HOME}"/LIVE_BOOT/chroot/usr/lib/systemd/network/99-default.link
[Link]
NamePolicy=kernel database onboard path slot
MACAddressPolicy=persistent
EOF
}

function _make_kernel(){
  mkdir -p "${HOME}"/LIVE_BOOT/{scratch,image/live}
  mksquashfs \
    "${HOME}"/LIVE_BOOT/chroot \
    "${HOME}"/LIVE_BOOT/image/live/filesystem.squashfs \
    -e boot

  cp "${HOME}"/LIVE_BOOT/chroot/boot/vmlinuz-* \
     "${HOME}"/LIVE_BOOT/image/vmlinuz &&
  cp "${HOME}"/LIVE_BOOT/chroot/boot/initrd.img-* \
     "${HOME}"/LIVE_BOOT/image/initrd
}

function _grub_install (){
  cp /builder/grub.conf "${HOME}"/LIVE_BOOT/scratch/grub.cfg

  touch "${HOME}/LIVE_BOOT/image/UBUNTU_CUSTOM"

  grub-mkstandalone \
    --format=i386-pc \
    --output="${HOME}/LIVE_BOOT/scratch/core.img" \
    --install-modules="linux normal iso9660 biosdisk memdisk search tar ls all_video" \
    --modules="linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    boot/grub/grub.cfg="${HOME}/LIVE_BOOT/scratch/grub.cfg"

  cat \
      /usr/lib/grub/i386-pc/cdboot.img "${HOME}/LIVE_BOOT/scratch/core.img" \
      > "${HOME}/LIVE_BOOT/scratch/bios.img"
}

function _make_iso(){
  xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "UBUNTU_CUSTOM" \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-boot \
        boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
    -output "/config/ubuntu-custom.iso" \
    -graft-points \
        "${HOME}/LIVE_BOOT/image" \
        /boot/grub/bios.img="${HOME}/LIVE_BOOT/scratch/bios.img"
}

function _make_metadata(){
  echo "bootImagePath: ${2:?}/ubuntu-custom.iso" > "${1:?}"
}

function _check_input_data_set_vars(){
  CHROOT="${HOME}/LIVE_BOOT/chroot"
  export CHROOT
  export CLOUD_DATA_LATEST="${HOME}/LIVE_BOOT/image/openstack/latest"
  echo "${BUILDER_CONFIG:?}"
  if [ ! -f "${BUILDER_CONFIG}" ]
  then
      echo "file ${BUILDER_CONFIG} not found"
      exit 1
  fi
  IFS=':' read -ra ADDR <<<"$(yq r "${BUILDER_CONFIG}" container.volume)"
  VOLUME="${ADDR[1]}"
  echo "${VOLUME:?}"
  if [[ "${VOLUME}" == 'none' ]]
  then
      echo "variable container.volume \
           is not present in $BUILDER_CONFIG"
      exit 1
  else
      if [[ ! -d "${VOLUME}" ]]
      then
          echo "${VOLUME} not exist"
          exit 1
      fi
  fi
  USER_DATA="${VOLUME}/$(yq r "${BUILDER_CONFIG}" builder.userDataFileName)"
  echo "${USER_DATA:?}"
  if [[ "${USER_DATA}" == 'none' ]]
  then
      echo "variable userDataFileName \
          is not present in ${BUILDER_CONFIG}"
      exit 1
  else
      if [[ ! -f ${USER_DATA} ]]
      then
          echo "${USER_DATA} not exist"
          exit 1
      fi
  fi
  NET_CONFIG="${VOLUME}/$(yq r "${BUILDER_CONFIG}" \
      builder.networkConfigFileName)"
  echo "${NET_CONFIG:?}"
  if [[ "${NET_CONFIG}" == 'none' ]]
  then
      echo "variable networkConfigFileName \
          is not present in ${BUILDER_CONFIG}"
      exit 1
      if [[ ! -f ${NET_CONFIG} ]]
      then
          echo "${NET_CONFIG} not exist"
          exit 1
      fi
  fi
}
