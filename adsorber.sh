#!/bin/bash

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT


readonly TMP_DIR_PATH="/tmp/adsorber"
readonly SCRIPT_DIR_PATH="$(cd "$(dirname "${0}")" && pwd)"
readonly SOURCELIST_FILE_PATH="${SCRIPT_DIR_PATH}/sources.list"

readonly VERSION="0.2.3"

readonly OPERATION="${1}"

# For better error messages, from http://wiki.bash-hackers.org/scripting/debuggingtips#making_xtrace_more_useful:
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

if [ "${#}" -ne 0 ]; then
        shift
fi


checkRoot()
{
        if [ "${UID}" -ne 0 ]; then
                echo "This script must be run as root." 1>&2
                exit 126
        fi

        return 0
}


checkForWrongParameters()
{
        if [ "${WRONG_OPERATION}" != "" ] || [ "${#WRONG_OPTION[@]}" -ne 0 ]; then
                showUsage
        fi

        if [ "${OPTION_HELP}" == "true"  ]; then
                showSpecificHelp
        fi

        return 0
}


showUsage()
{
        if [ "${WRONG_OPERATION}" != "" ]; then
                echo "Adsorber: Invalid operation: '${WRONG_OPERATION}'" 1>&2
        fi

        if [ "${WRONG_OPTION}" != "" ]; then
                echo "Adsorber: Invalid option: ${WRONG_OPTION[*]}" 1>&2
        fi

        echo "Usage: ${0} [install|remove|update|revert] {options}" 1>&2
        echo "Try --help for more information." 1>&2

        exit 127
}


showHelp()
{
        echo "Usage: ${0} [OPERATION] {options}"
        echo ""
        echo "A(d)sorber blocks ads by 'absorbing' and dumbing them into void."
        echo "           (with the help of the hosts file)"
        echo ""
        echo "Operations:"
        echo "  install - setup necessary things needed for Adsorber"
        echo "              e.g., create backup file of hosts file,"
        echo "                    create scheduler which updates the host file once a week."
        echo "  update  - update hosts file with newest ad servers"
        echo "  revert  - revert hosts file to its original state"
        echo "            (it does not remove the schedule, so this should be used temporary)"
        echo "  remove  - completely remove changes made by Adsorber"
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


showSpecificHelp()
{
        case "${OPERATION}" in
                install )
                        echo -e "${UWHITE}adsorber.sh install {options}${COLOUR_RESET}:"
                        echo ""
                        echo "You should run this command first."
                        echo ""
                        echo "The command will:"
                        echo " - backup your /etc/hosts file to /etc/hosts.original"
                        echo "   (if not other specified in adsorber.sh)"
                        echo " - install a scheduler which updates your hosts file with ad-server domains"
                        echo "   once a week. (either systemd, cronjob or none)"
                        echo " - install the newest ad-server domains in your hosts file."
                        echo ""
                        echo "Possible options are:"
                        echo " -s, --systemd"
                        echo " -c, --cronjob"
                        echo " -ns, --no-scheduler"
                        echo " -y, --yes, --assume-yes"
                        ;;
                update )
                        echo -e "${UWHITE}adsorber.sh update {options}${COLOUR_RESET}:"
                        echo ""
                        echo "To keep the hosts file up-to-date."
                        echo ""
                        echo "The command will:"
                        echo " - install the newest ad-server domains in your hosts file."
                        echo ""
                        echo "Possible option:"
                        echo " -f, --force"
                        ;;
                revert )
                        echo -e "${UWHITE}adsorber.sh revert {options}${COLOUR_RESET}:"
                        echo ""
                        echo "To restore the hosts file temporary."
                        echo ""
                        echo "The command will:"
                        echo " - copy /etc/hosts.original to /etc/hosts, overwriting the modified /etc/hosts by adsorber."
                        echo ""
                        echo "Important: If you have a scheduler installed,"
                        echo "it'll reapply ad-server domains to your hosts file after a while."
                        echo "For this reason this command is used to temporary disable Adsorber"
                        echo "(if it's blocking some sites you need access for a short period of time)."
                        echo "To reapply run asdorber.sh update"
                        ;;
                remove )
                        echo -e "${UWHITE}adsorber remove {options}${COLOUR_RESET}:"
                        echo ""
                        echo "To completely remove changes made by Adsorber."
                        echo ""
                        echo "The command will:"
                        echo " - remove all schedulers (systemd, cronjob)"
                        echo " - restore the hosts file to it's original state"
                        echo " - remove all leftovers"
                        echo ""
                        echo "Possible options are:"
                        echo " -y, --yes, --assume-yes"
                        echo " -f, --force"
                        ;;
        esac

        exit 0
}


showVersion()
{
        echo "A(d)sorber ${VERSION}"
        echo ""
        echo "  License MIT"
        echo "  Copyright (c) 2017 stablestud <adsorber@stablestud.org>"
        echo "  This is free software: you are free to change and redistribute it."
        echo "  There is NO WARRANTY, to the extent permitted by law."
        echo ""
        echo "Written by stablestud - and hopefully in the future with many others. ;)"
        echo "Repository: https://github.com/stablestud/adsorber"

        exit 0
}


duplicateOption()
{
        echo "Adsorber: Duplicate option: '${option}'"

        exit 127
}


sourceFiles()
{
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
                        readonly REPLY_TO_SCHEDULER_PROMPT="systemd" 2>/dev/null || duplicateOption
                        ;;
                -[Cc] | --cron )
                        readonly REPLY_TO_SCHEDULER_PROMPT="cronjob" 2>/dev/null || duplicateOption
                        ;;
                -[Nn][Ss] | --no-scheduler )
                        readonly REPLY_TO_SCHEDULER_PROMPT="no-scheduler" 2>/dev/null || duplicateOption
                        ;;
                -[Yy] | --[Yy][Ee][Ss] | --assume-yes )
                        readonly REPLY_TO_PROMPT="yes" 2>/dev/null || duplicateOption
                        ;;
                -[Ff] | --force )
                        readonly REPLY_TO_FORCE_PROMPT="yes" 2>/dev/null || duplicateOption
                        ;;
                "" )
                        : # Do nothing
                        ;;
                -[Hh] | --help | help )
                        readonly OPTION_HELP="true"
                        ;;
                * )
                        WRONG_OPTION+=("'${option}'")
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

echo -e "${PREFIX_TITLE}Successfully finished.${COLOUR_RESET}"

exit 0
