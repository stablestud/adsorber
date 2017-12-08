#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# CRONTAB_DIR_PATH          /etc/cron.weekly
# HOSTS_FILE_PATH           /etc/hosts
# HOSTS_FILE_BACKUP_PATH    /etc/hosts.original
# REPLY_TO_FORCE_PROMPT     Null (not set)
# REPLY_TO_PROMPT           Null (not set)
# REPLY_TO_SCHEDULER_PROMPT Null (not set)
# SCRIPT_DIR_PATH           The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH          /etc/systemd/system

copySourceList() {
  if [ ! -e "${SCRIPT_DIR_PATH}/sources.list" ]; then
    cp "${SCRIPT_DIR_PATH}/bin/default/default-sources.list" "${SCRIPT_DIR_PATH}/sources.list" \
      && echo "To add new host sources, please edit sources.list"
  fi
  return 0
}

backupHostsFile() {
  if [ ! -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
    cp "${HOSTS_FILE_PATH}" "${HOSTS_FILE_BACKUP_PATH}" \
      || echo "Successfully backed up ${HOSTS_FILE_PATH} to ${HOSTS_FILE_BACKUP_PATH}."
  else
    if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
      read -p "Backup of ${HOSTS_FILE_PATH} already exist. Continue? [YES/n]: " REPLY_TO_FORCE_PROMPT
    fi
    case "${REPLY_TO_FORCE_PROMPT}" in
      [Yy][Ee][Ss] )
        :
        ;;
      * )
        echo "Aborted."
        exit 1
        ;;
    esac
  fi
  return 0
}

installCronjob() {
  echo "Installing cronjob..."
  cp "${SCRIPT_DIR_PATH}/bin/cron/80adsorber" "${CRONTAB_DIR_PATH}"
  sed -i "s|@.*|${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${CRONTAB_DIR_PATH}/80adsorber"
  return 0
}

installSystemd() {
  echo "Installing systemd service..."
  cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.service" "${SYSTEMD_DIR_PATH}/adsorber.service"
  sed -i "s|@ExecStart.*|ExecStart=${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SYSTEMD_DIR_PATH}/adsorber.service"
  cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.timer"
  systemctl daemon-reload \
    && systemctl enable adsorber.timer \
    && systemctl start adsorber.timer || echo "Couldn't start systemd service."
  return 0
}

promptInstall() {
  if [ -z "${REPLY_TO_PROMPT}" ]; then
    read -p "Do you really want to install adsorber? [Y/n]: " REPLY_TO_PROMPT
  fi
  case "${REPLY_TO_PROMPT}" in
    [Yy] | [Yy][Ee][Ss] )
      unset REPLY_TO_PROMPT
      ;;
    * )
      echo "Installation cancelled."
      exit 1
      ;;
  esac
  return 0 # maybe return $REPLY_TO_PROMPT?
}

promptScheduler() {
  if [ -z "${REPLY_TO_SCHEDULER_PROMPT}" ]; then
    read -p "What scheduler should be used to update hosts file automatically? [(S)ystemd/(C)ron/(N)one]: " REPLY_TO_SCHEDULER_PROMPT
  fi
  case "${REPLY_TO_SCHEDULER_PROMPT}" in
    [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
      installSystemd
      ;;
    [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
      installCronjob
      ;;
    * )
      echo "Skipping scheduler creation..."
      ;;
  esac
  return 0
}
