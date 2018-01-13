#!/bin/bash

readonly TMP_DIR_PATH="/tmp/adsorber"
readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${0}")" && pwd)"
readonly SOURCELIST_FILE_PATH="${SCRIPT_DIR_PATH}/sources.list"

readonly VERSION="0.2.1"

readonly OPERATION="${1}"

if [ "${#}" -ne 0 ]; then
    shift
fi


checkRoot() {
    if [ "${UID}" -ne 0 ]; then
        echo -e "This script must be run as root." 1>&2
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
        echo -e "Adsorber: Invalid operation: '${WRONG_OPERATION}'" 1>&2
    fi

    if [ "${WRONG_OPTION}" != "" ]; then
        echo -e "Adsorber: Invalid option: ${WRONG_OPTION[@]}" 1>&2
    fi

    echo -e "Usage: ${0} [install|remove|update|revert] {options}" 1>&2
    echo -e "Try --help for more information." 1>&2

    exit 127
}


showHelp() {
    echo -e "Usage: ${0} [OPERATION] {options}"
    echo -e ""
    echo -e "A(d)sorber blocks ads by 'absorbing' and dumbing them into void."
    echo -e "           (with the help of the hosts file)"
    echo -e ""
    echo -e "Operations:"
    echo -e "  install - setup necessary things needed for adsorber"
    echo -e "              e.g., create backup file of hosts file,"
    echo -e "                    create scheduler which updates the host file once a week."
    echo -e "  update  - update hosts file with newest ad servers"
    echo -e "  revert  - revert hosts file to its original state"
    echo -e "            (it does not remove the schedule, so this should be used temporary)"
    echo -e "  remove  - completely remove changes made by adsorber"
    echo -e "              e.g., remove scheduler (if set)"
    echo -e "                    revert hosts file (if not already done)"
    echo -e "  version - show version of this shell script"
    echo -e "  help    - show this help"
    echo -e ""
    echo -e "Options: (not required)"
    echo -e "  -s,  --systemd           - use systemd ..."
    echo -e "  -c,  --cron              - use cron as scheduler (use with 'install')"
    echo -e "  -ns, --no-scheduler      - set no scheduler (use with 'install')"
    echo -e "  -y,  --yes, --assume-yes - answer all prompts with 'yes'"
    echo -e "  -f,  --force             - force the update if no /etc/hosts backup"
    echo -e "                             has been created (dangerous)"
    echo -e ""
    echo -e "Documentation: https://github.com/stablestud/adsorber"
    echo -e "If you encounter any issues please report them to the Github repository."

    exit 0
}


showVersion() {
    echo -e "A(d)sorber ${VERSION}

  License MIT
  Copyright (c) 2017 stablestud
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.

  Written by stablestud - and hopefully in the future with many others. ;)
  Repository: https://github.com/stablestud/adsorber"

    exit 0
}


sourceFiles() {
    . "${SCRIPT_DIR_PATH}/bin/install.sh"
    . "${SCRIPT_DIR_PATH}/bin/remove.sh"
    . "${SCRIPT_DIR_PATH}/bin/update.sh"
    . "${SCRIPT_DIR_PATH}/bin/revert.sh"
    . "${SCRIPT_DIR_PATH}/bin/config.sh"
    . "${SCRIPT_DIR_PATH}/bin/colours.sh"

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
        config
        install
        update
        ;;
    remove )
        checkForWrongParameters
        checkRoot
        config
        remove
        ;;
    update )
        checkForWrongParameters
        checkRoot
        config
        update
        ;;
    revert )
        checkForWrongParameters
        checkRoot
        config
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

echo -e "${PREFIX}${BWHITE}Finished.${COLOUR_RESET}"

exit 0
