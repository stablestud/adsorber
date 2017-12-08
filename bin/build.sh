#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original
# TMP_DIR_PATH            /tmp/adsorber

readWhitelist() {
  cat "${SCRIPT_DIR_PATH}/white.list"
}

readBlacklist() {
  cat "${SCRIPT_DIR_PATH}/black.list"
}

buildCleanUp() {
  echo "Cleaning up..."
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

buildHostsFile() {
  # Glue all pieces of the hosts file together
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts.header" \
    | sed "s|@.\+@|${HOSTS_FILE_BACKUP_PATH}|g" >> "${TMP_DIR_PATH}/hosts"
  # Add an empty line between comment and content
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${HOSTS_FILE_BACKUP_PATH}" >> "${TMP_DIR_PATH}/hosts" \
    || echo "You may want to add your hostname to ${HOSTS_FILE_PATH}"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts.title" >> "${TMP_DIR_PATH}/hosts"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${TMP_DIR_PATH}/hosts.sorted" >> "${TMP_DIR_PATH}/hosts"
  return 0
}

applyHostsFile() {
  # Replace systems hosts file with the modified version
  echo "Applying new hosts file."
  cat "${TMP_DIR_PATH}/hosts" > "${HOSTS_FILE_PATH}" \
    || {
      echo "Couldn't apply hosts file. Aborting"
      buildCleanUp
      exit 1
  }
  return 0
}
