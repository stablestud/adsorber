#!/bin/bash
# This file needs variable REPLY_TO_PROMPT HOSTS_FILE HOSTS_FILE_BACKUP set

backupHostsFile() {
  cp "${HOSTS_FILE}" "${HOSTS_FILE_BACKUP}"
  #  || (echo "Failed to backup ${HOSTS_FILE}")
  # Add checker if file exist
  return 0
}

installCronjob() {
  return 0
  # already exist? overwriting
}

installSystemd() {
  return 0
}

promptInstall() {
  if [ -z "${REPLY_TO_PROMPT}" ]; then
    read -p "Do you really want to install adsorber? [Y/n]" REPLY_TO_PROMPT
  fi
  case "${REPLY_TO_PROMPT}" in
    [Yy] | [Yy][Ee][Ss] )
      backupHostsFile
      ;;
    * )
      echo "Installation cancelled."
      exit 1
      ;;
  esac
  return 0 # maybe return $REPLY_TO_PROMPT?
}

promptScheduler() {
  if [ -z "${SCHEDULER}" ]; then
    read -p "What scheduler should be used to update hosts file automatically? [systemd/cron/N]" SCHEDULER
  fi
  case "${SCHEDULER}" in
    [Ss]ystemd )
      installSystemd
      ;;
    [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
      installCronjob
      ;;
    * )
      echo "Skipping scheduler creation..."
      ;;
  esac
  return 0
}

install() {
  promptInstall
  promptScheduler
  return 0
}
