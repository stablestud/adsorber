#!/bin/bash

HOSTS_FILE_PATH="/etc/hosts"
HOSTS_FILE_BACKUP_PATH="/etc/hosts.original"
TMP_DIR_PATH="/tmp/adsorber"
SCRIPT_DIR_PATH="$(cd "$(dirname "${0}")" && pwd)"
SOURCES_FILE_PATH="${SCRIPT_DIR_PATH}/sources.list"
CRONTAB_DIR_PATH="/etc/cron.weekly"
SYSTEMD_DIR_PATH="/etc/systemd/system"

VERSION="0.1.0"

OPERATION="${1}"

checkRoot() {
  if [ "${UID}" -ne 0 ]; then
    echo "This script must be run as root." 1>&2
    exit 126
  fi
  return 0
}

checkForWrongParameters() {
  if [ "${WRONG_OPERATION}" != "" ] || [ "${#WRONG_OPTION[@]}" -ne 0 ]; then
    showUsage
  fi
  return 0
}

showUsage() {
  if [ "${WRONG_OPERATION}" != "" ]; then
    echo "adsorber: Invalid operation: '${WRONG_OPERATION}'" 1>&2
  fi
  if [ "${WRONG_OPTION}" != "" ]; then
    echo "adsorber: Invalid option: ${WRONG_OPTION[@]}" 1>&2
  fi
  echo "Usage: ${0} [install|update|revert|remove] {options}" 1>&2
  echo "Try '${0} --help' for more information." 1>&2
  exit 127
}

showHelp() {
  echo "Usage: ${0} [OPERATION] {options}"
  echo ""
  echo "A(d)sorber blocks ads by 'absorbing' and dumbing them into void."
  echo "           (with the help of the hosts file)"
  echo ""
  echo "Operations:"
  echo "  install - setup necessary things needed for adsorber "
  echo "              e.g., create backup file of hosts file,"
  echo "                    create a list with host sources to fetch from"
  echo "  update  - update hosts file with newest ad servers"
  echo "  revert  - revert hosts file to its original state"
  echo "            (it does not remove the schedule, so this should be used temporary)"
  echo "  remove  - completely remove changes made by adsorber"
  echo "              e.g., remove scheduler (if set)"
  echo "                    revert hosts file (if not already done)"
  echo "  version - show version of this shell script"
  echo "  help    - show this help"
  echo ""
  echo "Options: (not required)"
  echo "  -s,  --systemd           - use systemd ..."
  echo "  -c,  --cron              - use cron as scheduler (use with 'install')"
  echo "  -ns, --no-scheduler      - set no scheduler (use with 'install')"
  echo "  -y,  --yes, --assume-yes - answer all prompts with 'yes'"
  echo "  -f,  --force             - force the installation (dangerous)"
  echo ""
  echo "Documentation: https://github.com/stablestud/adsorber"
  echo "If you encounter any issues please report them to the Github repository."
  exit 0
}

showVersion() {
  echo "A(d)sorber ${VERSION}

  Copyright (c) 2017 stablestud
  License MIT
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.

  Written by stablestud - and hopefully in the future with many others. ;)"
  exit 0
}

sourceFiles() {
  . "${SCRIPT_DIR_PATH}/bin/install.sh"
  . "${SCRIPT_DIR_PATH}/bin/update.sh"
  . "${SCRIPT_DIR_PATH}/bin/revert.sh"
  . "${SCRIPT_DIR_PATH}/bin/remove.sh"
}

if [ "${#}" -ne 0 ]; then
  shift
fi

sourceFiles

for OPTION in "${@}"; do
  case "${OPTION}" in
    -[Ss] | --systemd )
      REPLY_TO_SCHEDULER_PROMPT="systemd"
      ;;
    -[Cc] | --cron )
      REPLY_TO_SCHEDULER_PROMPT="cronjob"
      ;;
    -[Nn][Ss] | --no-scheduler )
      REPLY_TO_SCHEDULER_PROMPT="no-scheduler"
      ;;
    -[Yy] | --[Yy][Ee][Ss] | --assume-yes )
      REPLY_TO_PROMPT="yes"
      ;;
    -[Ff] | --force )
      REPLY_TO_FORCE_PROMPT="yes"
      ;;
    "" )
      : # Do nothing
      ;;
    * )
      WRONG_OPTION+=("'${OPTION}'")
      ;;
  esac
done

case "${OPERATION}" in
  update )
    checkForWrongParameters
    checkRoot
    update
    ;;
  remove )
    checkForWrongParameters
    checkRoot
    remove
    ;;
  revert )
    checkForWrongParameters
    checkRoot
    revert
    ;;
  install )
    checkForWrongParameters
    checkRoot
    install
    update
    ;;
  -[Hh] | help | --help )
    showHelp
    ;;
  -[Vv] | version | --version )
    showVersion
    ;;
  "" )
    showUsage
    ;;
  * )
    WRONG_OPERATION="${OPERATION}"
    showUsage
    ;;
esac

echo "Finished."
exit 0
