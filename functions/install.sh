#!/bin/bash
# This file needs variable HOSTS_FILE HOSTS_FILE_BACKUP set

backupHostsFile() {
  cp "${HOSTS_FILE}" "${HOSTS_FILE_BACKUP}" 
  #  || (echo "Failed to backup ${HOSTS_FILE}")
  return 0
}

installCronjob() {
  return 0
}

installSystemd() {
  return 0
}

install() {
  backupHostsFile
  #case "${SCHEDULER}" in
  #  systemd )
  #    installSystemd
  #    ;;
  #  cronjob )
  #    installCronjob
  #    ;;
  #  no-scheduler )
  #    # NO scheduler set
  #    ;;
  #  * )
  #    read
  #    ;;
  #esac
  return 0
}
