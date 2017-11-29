#!/bin/bash

HOSTS_FILE="/etc/hosts"
HOSTS_FILE_BACKUP="/etc/hosts.original"
SCRIPT_PATH="$(cd "$(dirname "${0}")" && pwd)"
TMP_DIR_PATH="/tmp/adsorber"

VERSION="0.1.0"

OPERATION="${1}"

checkRoot() {
  if [ "${UID}" -ne 0 ]; then
    echo "This script must be run as root." 1>&2
    exit 1
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
  echo "Usage: ${0} [setup|update|revert|remove] {options}" 1>&2
  echo "Try '${0} --help' for more information." 1>&2
  exit 1
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
  echo "  -s, --systemd - set systemd ..."
  echo "  -c, --cronjob - set cronjob as scheduler (use with 'install')"
  echo "  -ns, --no-scheduler - set no scheduler (use with 'install')"
  echo "  -y, --yes, --assume-yes - answer all prompts with 'yes'"
  exit 0
}

showVersion() {
  echo "A(d)sorber ${VERSION}"
  echo ""
  echo "Copyright (c) 2017 stablestud"
  echo "License MIT"
  echo "This is free software: you are free to change and redistribute it."
  echo "There is NO WARRANTY, to the extent permitted by law."
  echo ""
  echo "Written by stablestud - and hopefully in the future with many others. ;)"
  exit 0
}

sourceFunctions() {
  # Sourcing functions in a function? Will this break things?
  . "${SCRIPT_PATH}/functions/install.sh"
  . "${SCRIPT_PATH}/functions/update.sh"
  . "${SCRIPT_PATH}/functions/revert.sh"
  . "${SCRIPT_PATH}/functions/remove.sh"
}

if [ "${#}" -ne 0 ]; then
  shift
fi

sourceFunctions

for OPTION in "${@}"; do
  case "${OPTION}" in
    -[Ss] | --systemd )
      SCHEDULER="sytemd"
      ;;
    -[Cc] | --cronjob )
      SCHEDULER="cronjob"
      ;;
    -[Nn][Ss] | --no-scheduler )
      SCHEDULER="no-scheduler"
      ;;
    -[Yy] | --[Yy][Es][Ss] | --assume-yes )
      ASSUME_YES="true"
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
    #checkForWrongParameters
    #root
    #fetchSources
    #buildHosts "${ASSUME_YES}"
    ;;
  remove )
    #checkForWrongParameters
    #checkRoot
    #revertHostsFile "${ASSUME_YES}"
    #remove "${ASSUME_YES}"
    ;;
  revert )
    #checkForWrongParameters
    checkRoot
    revertHostsFile
    ;;
  install )
    checkForWrongParameters
    checkRoot
    install
    #fetchSources
    #buildHostsFile "${ASSUME_YES}"
    ;;
  -h | help | --help )
    showHelp
    ;;
  -v | version | --version )
    showVersion
    ;;
  "" )
    showUsage
    ;;
  * )
    WRONG_OPERATION="${OPERATION}"
    ;;
esac
