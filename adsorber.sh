#!/bin/bash

# Author:     stablestud <dev@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT


readonly TMP_DIR_PATH="/tmp/adsorber"
readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${0}")" && pwd)"
readonly SOURCELIST_FILE_PATH="${SCRIPT_DIR_PATH}/sources.list"

readonly VERSION="0.2.2"

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
        echo "Adsorber: Invalid operation: '${WRONG_OPERATION}'" 1>&2
    fi

    if [ "${WRONG_OPTION}" != "" ]; then
        echo "Adsorber: Invalid option: ${WRONG_OPTION[@]}" 1>&2
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
    echo "  install - setup necessary things needed for adsorber"
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
    echo "  -s,  --systemd           - use Systemd ..."
    echo "  -c,  --cron              - use Cronjob as scheduler (use with 'install')"
    echo "  -ns, --no-scheduler      - skip scheduler creation (use with 'install')"
    echo "  -y,  --yes, --assume-yes - answer all prompts with 'yes'"
    echo "  -f,  --force             - force the update if no /etc/hosts backup"
    echo "                             has been created (dangerous)"
    echo ""
    echo "Documentation: https://github.com/stablestud/adsorber"
    echo "If you encounter any issues please report them to the Github repository."

    exit 0
}


showVersion() {
    echo "A(d)sorber ${VERSION}

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

echo -e "${PREFIX_TITLE}Finished.${COLOUR_RESET}"

exit 0
