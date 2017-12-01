#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:---   ---default value:---
# CRONTAB_DIR_PATH  /etc/cron.weekly
# REPLY_TO_PROMPT   Null (not set)
# SCRIPT_DIR_PATH   The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH  /etc/systemd/system

removeSystemd() {
  if [ -e "${SYSTEMD_DIR_PATH}/adsorber.service" ]; then
    systemctl stop adsorber.timer \
    && systemctl disable adsorber.timer
    #systemctl stop adsorber.service 2>/dev/null 1>&2
    #systemctl disable adsorber.server 2/dev/null 1>&2 # Is not enabled by default
    rm "${SYSTEMD_DIR_PATH}/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.service" \
    || echo "Couldn't remove systemd service files."
    systemctl daemon-reload
    echo "Removed adsorber's systemd service."
  else
    echo "Systemd service not installed. Skipping..."
  fi
  return 0
}

removeCronjob(){
  if [ -e "${CRONTAB_DIR_PATH}/80adsorber" ]; then
    rm "${CRONTAB_DIR_PATH}/80adsorber"
    echo "Removed adsorber's cronjob."
  else
    echo "Cronjob not installed. Skipping..."
  fi
  return 0
}

promptRemove() {
  if [ -z "${REPLY_TO_PROMPT}" ]; then
    read -p "Do you really want to remove adsorber? [Y/n] " REPLY_TO_PROMPT
  fi
  case "${REPLY_TO_PROMPT}" in
    [Yy] | [Yy][Ee][Ss] )
      unset REPLY_TO_PROMPT
      ;;
    * )
      echo "Remove cancelled."
      exit 1
      ;;
  esac
  return 0
}

removeOriginalHostsFile() {
  rm -f "${HOSTS_FILE_BACKUP_PATH}"
  return 0
}

remove() {
  promptRemove
  removeSystemd
  removeCronjob
  return 0
}
