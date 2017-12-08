#!/bin/bash

checkBackupExist() {
  if [ ! -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
    if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
      echo "Backup of ${HOSTS_FILE_PATH} does not exist. To backup run '${0} install'." 1>&2
      read -p "Ignore issue and continue? (May break your system, not recommended) [YES/n]: " REPLY_TO_FORCE_PROMPT
    fi
    case "${REPLY_TO_FORCE_PROMPT}" in
      [Yy][Ee][Ss] )
        :
        ;;
      * )
        echo "Aborted." 1>&2
        exit 1
        ;;
    esac
  fi
  return 0
}

createTmpDir() {
  if [ ! -d ${TMP_DIR_PATH} ]; then
    mkdir "${TMP_DIR_PATH}"
  else
    echo "Removing previous tmp folder..."
    rm -rf "${TMP_DIR_PATH}"
    mkdir "${TMP_DIR_PATH}"
  fi
  return 0
}
