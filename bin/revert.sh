#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original


revertHostsFile() {
  if [ -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
    cp "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}" \
      && echo "Successfully reverted ${HOSTS_FILE_PATH}." \
      && echo "To reapply please run './adsorber.sh update'"
  else
    echo "Can not restore hosts file. Original hosts file does not exist." 1>&2
    exit 1
  fi
  return 0
}

revert() {
  echo "Reverting ${HOSTS_FILE_PATH}..."
  revertHostsFile
  return 0
}
