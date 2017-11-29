#!/bin/bash

VERSION="0.1.0"
OPERATION="${1}"
SCRIPT_LOCATION="$(cd "$(dirname "${0}")" && pwd)"


showUsage() {
  if [ "${WRONG_OPERATION}" != "" ]; then
    echo "adsorber: Invalid operation: '${WRONG_OPERATION}'"
  fi
  if [ "${WRONG_OPTION}" != "" ]; then
    echo "adsorber: Invalid option: ${WRONG_OPTION[@]}"
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
  echo "  setup   - setup necessary things needed for adsorber "
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
  echo "  -s, --systemd  set systemd ..."
  echo "  -c, --cronjob  set cronjob as scheduler (use with 'setup')"
  echo "  -y, --yes      answer all prompts with 'yes'"
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
  . "${SCRIPT_LOCATION}/functions/update.sh"
  . "${SCRIPT_LOCATION}/functions/remove.sh"
  . "${SCRIPT_LOCATION}/functions/revert.sh"
  . "${SCRIPT_LOCATION}/functions/schedule.sh"
    # Home of systemd and cronjob implementation
  . "${SCRIPT_LOCATION}/functions/setup.sh"
}

cleanUp() {
  echo "hello"
  # Clean up leftovers
}

if [ "${#}" -ne 0 ]; then
  shift
fi

for OPTION in "${@}"; do
  case "${OPTION}" in
    -[Ss] | --systemd )
      SCHEDULER="sytemd"
    ;;
    -[Cc] | --cronjob )
      SCHEDULER="cronjob"
    ;;
    -[Yy] | --[Yy][Es][SS] | --assume-yes )
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
  remove )
    #remove "${ASSUME_YES}"
  ;;
  revert )
    #revert "${ASSUME_YES}"
  ;;
  update )
    #fetch
    #build "${ASSUME_YES}"
  ;;
  setup )
    #setup "${ASSUME_YES}" "${SCHEDULER}"
  ;;
  -h | help | --help )
    showHelp
  ;;
  -v | version | --version )
    showVersion
  ;;
  * )
    WRONG_OPERATION="${OPERATION}"
  ;;
esac

if [ "${WRONG_OPERATION}" != "" ] || [ "${#WRONG_OPTION[@]}" -ne 0 ]; then
  showUsage
fi
