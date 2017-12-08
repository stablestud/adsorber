#!/bin/bash

readonly HOSTS_FILE_PATH="/etc/hosts"
readonly HOSTS_FILE_BACKUP_PATH="/etc/hosts.original"
readonly TMP_DIR_PATH="/tmp/adsorber"
readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${0}")" && pwd)"
readonly SOURCE_FILE_PATH="${SCRIPT_DIR_PATH}/sources.list"
readonly CRONTAB_DIR_PATH="/etc/cron.weekly"
readonly SYSTEMD_DIR_PATH="/etc/systemd/system"

readonly VERSION="0.1.0"

readonly OPERATION="${1}"

if [ "${#}" -ne 0 ]; then
  shift
fi

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
  echo "Usage: ${0} [install|remove|update|revert] {options}" 1>&2
  echo "Try --help for more information." 1>&2
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
  echo "                    create scheduler which updates the host file once a week."
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
  echo "  -f,  --force             - force the installation/update (dangerous)"
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

install() {
  echo "Installing Adsorber..."
  copySourceList
  promptInstall
  backupHostsFile
  promptScheduler
  return 0
}

remove() {
  echo "Removing Adsorber..."
  promptRemove
  removeSystemd
  removeCronjob
  removeHostsFile
  removeCleanUp
  return 0
}

update() {
  echo "Updating ${HOSTS_FILE_PATH}..."
  readSourceList
  checkBackupExist
  createTmpDir
  fetchSources
  filterDomains
  sortDomains
  buildHostsFile
  applyHostsFile
  updateCleanUp
  return 0
}

revert() {
  echo "Reverting ${HOSTS_FILE_PATH}..."
  revertHostsFile
  return 0
}

sourceFiles() {
  . "${SCRIPT_DIR_PATH}/bin/install.sh"
  . "${SCRIPT_DIR_PATH}/bin/remove.sh"
  . "${SCRIPT_DIR_PATH}/bin/update.sh"
  . "${SCRIPT_DIR_PATH}/bin/revert.sh"
  . "${SCRIPT_DIR_PATH}/bin/build.sh"
  . "${SCRIPT_DIR_PATH}/bin/filter.sh"
  . "${SCRIPT_DIR_PATH}/bin/pre.sh"
  return 0
}

sourceFiles

for option in "${@}"; do
  case "${option}" in
    -[Ss] | --systemd )
      readonly REPLY_TO_SCHEDULER_PROMPT="systemd"
      ;;
    -[Cc] | --cron )
      readonly REPLY_TO_SCHEDULER_PROMPT="cronjob"
      ;;
    -[Nn][Ss] | --no-scheduler )
      readonly REPLY_TO_SCHEDULER_PROMPT="no-scheduler"
      ;;
    -[Yy] | --[Yy][Ee][Ss] | --assume-yes )
      readonly REPLY_TO_PROMPT="yes"
      ;;
    -[Ff] | --force )
      readonly REPLY_TO_FORCE_PROMPT="yes"
      ;;
    "" )
      : # Do nothing
      ;;
    * )
      readonly WRONG_OPTION+=("'${option}'")
      ;;
  esac
done

case "${OPERATION}" in
  install )
    checkForWrongParameters
    checkRoot
    install
    update
    ;;
  remove )
    checkForWrongParameters
    checkRoot
    remove
    ;;
  update )
    checkForWrongParameters
    checkRoot
    update
    ;;
  revert )
    checkForWrongParameters
    checkRoot
    revert
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
    readonly WRONG_OPERATION="${OPERATION}"
    showUsage
    ;;
esac

echo "Finished."
exit 0
