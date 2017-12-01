#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         "/etc/hosts"
# HOSTS_FILE_BACKUP_PATH  "/etc/hosts.original"


revertHostsFile() {
  mv "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}"
  echo "Hosts file restored."
  return 0
}

revert() {
  revertHostsFile
  return 0
}
