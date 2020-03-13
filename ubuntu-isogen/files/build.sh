#!/bin/bash

BASEDIR="$(dirname "$(realpath "$0")")"
# shellcheck source=files/functions.sh
source "${BASEDIR}/functions.sh"

set -xe

_check_input_data_set_vars

_debootstrap

chroot "${CHROOT}" < "${BASEDIR}/packages_install.sh"

mkdir -p "${CLOUD_DATA_LATEST}"
cp "${BASEDIR}/meta_data.json" "${CLOUD_DATA_LATEST}"
cp "${USER_DATA}" "${CLOUD_DATA_LATEST}/user_data"
cp "${NET_CONFIG}" "${CLOUD_DATA_LATEST}/network_data.json"
echo "datasource_list: [ ConfigDrive, None ]" > \
    "${CHROOT}/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg"

_make_kernel
_grub_install
_make_iso

OUTPUT="$(yq r "${BUILDER_CONFIG}" builder.outputMetadataFileName)"
HOST_PATH="${ADDR[0]}"
_make_metadata "${VOLUME}/${OUTPUT}" "${HOST_PATH}"
