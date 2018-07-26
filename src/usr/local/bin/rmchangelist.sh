#!/bin/sh
# rmchangelist - remove local changelist backups

set -o errexit
set -o nounset

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

changelist_local="/etc/changelist.local"
changelist_tmp="$(mktemp)"

if [ -r "${changelist_local}" ]
  then
    cp "${changelist_local}" "${changelist_tmp}"
    sed -i 's|^+||g' "${changelist_tmp}"
    sed -i 's|/|_|g' "${changelist_tmp}"
    sed -i 's|^_|rm /var/backups/|g' "${changelist_tmp}"
    sed -i '/^rm/ s|$|*|g' "${changelist_tmp}"
    sed -i '1s| changelist.local|!/bin/sh|' "${changelist_tmp}"
    chmod 500 "${changelist_tmp}"
    "${changelist_tmp}"
    rm "${changelist_tmp}"
  else
    ls "${changelist_local}"
fi
