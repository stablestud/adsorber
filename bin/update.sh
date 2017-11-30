#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:---   ---default value:---
# CRONTAB_DIR_PATH  "/etc/cron.weekly"
# HOSTS_FILE        "/etc/hosts"
# HOSTS_FILE_BACKUP "/etc/hosts.original"
# REPLY_TO_PROMPT   Null (not set)
# SCRIPT_DIR_PATH   The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCES_FILE_PATH "${SCRIPT_DIR_PATH}/sources.list" (e.g., /home/user/Downloads/absorber/sources.list)
# SYSTEMD_DIR_PATH  "/etc/systemd/system"

createTmpDir() {
  mkdir "${TMP_DIR_PATH}"
  return 0
}

readSourceFile() {
  while read LINE; do
    :  # DO LATER
  done < "${SOURCES_FILE_PATH}"
  return 0
}

fetchSources() {
  #check if hostsources exist
  return 0
}

buildHostsFile() {
  return 0
}

cleanUp() {
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

update() {
  createTmpDir
  readSourceFile
  fetchSources
  buildHostsFile
  cleanUp
  return 0
}
