#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT


readonly tmp_dir_path="/tmp/adsorber"
readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"
readonly sourcelist_file_path="${script_dir_path}/sources.list"

readonly version="0.3.0"

readonly operation="${1}"

# For better error messages, from http://wiki.bash-hackers.org/scripting/debuggingtips#making_xtrace_more_useful:
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

if [ "${#}" -ne 0 ]; then
        shift
fi


checkRoot()
{
        if [ "$(id -g)" -ne 0 ]; then
                echo "This script must be run as root." 1>&2
                exit 126
        fi

        return 0
}


checkForWrongParameters()
{
        if [ ! -z "${wrong_operation}" ] || [ ! -z "${wrong_option}" ]; then
                showUsage
        fi

        if [ "${option_help}" = "true"  ]; then
                showSpecificHelp
        fi

        return 0
}


showUsage()
{
        if [ ! -z "${wrong_operation}" ]; then
                echo "Adsorber: Invalid operation: '${wrong_operation}'" 1>&2
        fi

        if [ ! -z "${wrong_option}" ]; then
                echo "Adsorber: Invalid option: '${wrong_option}'" 1>&2
        fi

        echo "Usage: ${0} [install|remove|update|restore|revert] {options}" 1>&2
        echo "Try --help for more information." 1>&2

        exit 127
}


showHelp()
{
        echo "Usage: ${0} [operation] {options}"
        echo ""
        echo "A(d)sorber blocks ads by 'absorbing' and dumbing them into void."
        echo "           (with the help of the hosts file)"
        echo ""
        echo "Operations:"
        echo "  install - setup necessary things needed for Adsorber"
        echo "              e.g., create backup file of hosts file,"
        echo "                    create scheduler which updates the host file once a week"
        echo "  update  - update hosts file with newest ad servers"
        echo "  restore - restore hosts file to its original state"
        echo "            (it does not remove the schedule, so this should be used temporary)"
        echo "  remove  - completely remove changes made by Adsorber"
        echo "              e.g., remove scheduler (if set)"
        echo "                    restore hosts file (if not already done) to its original state"
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
        case "${operation}" in
                install )
                        printf "%badsorber.sh install {options}%b:\n" "${uwhite}" "${prefix_reset}"
                        echo ""
                        echo "You should run this command first."
                        echo ""
                        echo "The command will:"
                        echo " - backup your /etc/hosts file to /etc/hosts.original"
                        echo "   (if not other specified in adsorber.conf)"
                        echo " - install a scheduler which updates your hosts file with ad-server domains"
                        echo "   once a week. (either systemd, cronjob or none)"
                        echo " - install the newest ad-server domains in your hosts file."
                        echo ""
                        echo "Possible options are:"
                        echo " -s, --systemd            - use Systemd ..."
                        echo " -c, --cronjob            - use Cronjob as scheduler"
                        echo " -ns, --no-scheduler      - skip scheduler creation"
                        echo " -y, --yes, --assume-yes  - answer all prompts with 'yes'"
                        ;;
                update )
                        printf "%badsorber.sh update {options}%b:\n" "${uwhite}" "${prefix_reset}"
                        echo ""
                        echo "To keep the hosts file up-to-date."
                        echo ""
                        echo "The command will:"
                        echo " - install the newest ad-server domains in your hosts file."
                        echo ""
                        echo "Possible option:"
                        echo " -f, --force      - force the update if no /etc/hosts backup"
                        echo "                    has been created (dangerous)"
                        ;;
                restore )
                        printf "%badsorber.sh restore {options}%b:\n" "${uwhite}" "${prefix_reset}"
                        echo ""
                        echo "To restore the hosts file temporary, without removing the backup."
                        echo ""
                        echo "The command will:"
                        echo " - copy /etc/hosts.original to /etc/hosts, overwriting the modified /etc/hosts by adsorber."
                        echo ""
                        echo "Important: If you have a scheduler installed it'll re-apply ad-server domains to your hosts"
                        echo "file when triggered."
                        echo "For this reason this command is used to temporary disable Adsorber."
                        echo "(e.g. when it's blocking some sites you need access for a short period of time)"
                        echo ""
                        echo "To re-apply run 'asdorber.sh update'"
                        ;;
                remove )
                        printf "%badsorber remove {options}%b:\n" "${uwhite}" "${prefix_reset}"
                        echo ""
                        echo "To completely remove changes made by Adsorber."
                        echo ""
                        echo "The command will:"
                        echo " - remove all schedulers (systemd, cronjob)"
                        echo " - restore the hosts file to it's original state"
                        echo " - remove all leftovers"
                        echo ""
                        echo "Possible option:"
                        echo " -y, --yes, --assume-yes  - answer all prompts with 'yes'"
                        ;;
        esac

        exit 0
}


showVersion()
{
        echo "A(d)sorber ${version}"
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
        if [ "${1}" = "scheduler" ]; then
                echo "Adsorber: Duplicate option for scheduler: '${option}'"
                echo "You may only select one:"
                echo "  -s,  --systemd           - use Systemd ..."
                echo "  -c,  --cron              - use Cronjob as scheduler (use with 'install')"
                echo "  -ns, --no-scheduler      - skip scheduler creation (use with 'install')"
        else
                echo "Adsorber: Duplicate option: '${option}'"
                showUsage
        fi

        exit 127
}


sourceFiles()
{
        . "${script_dir_path}/bin/install.sh"
        . "${script_dir_path}/bin/remove.sh"
        . "${script_dir_path}/bin/update.sh"
        . "${script_dir_path}/bin/restore.sh"
        . "${script_dir_path}/bin/config.sh"
        . "${script_dir_path}/bin/colours.sh"
        return 0
}


sourceFiles

for option in "${@}"; do

        case "${option}" in
                -[Ss] | --systemd )
                        readonly reply_to_scheduler_prompt="systemd" 2>/dev/null || duplicateOption "scheduler"
                        ;;
                -[Cc] | --cron )
                        readonly reply_to_scheduler_prompt="cronjob" 2>/dev/null || duplicateOption "scheduler"
                        ;;
                -[Nn][Ss] | --no-scheduler )
                        readonly reply_to_scheduler_prompt="no-scheduler" 2>/dev/null || duplicateOption "scheduler"
                        ;;
                -[Yy] | --[Yy][Ee][Ss] | --assume-yes )
                        readonly reply_to_prompt="yes" 2>/dev/null || duplicateOption
                        ;;
                -[Ff] | --force )
                        readonly reply_to_force_prompt="yes" 2>/dev/null || duplicateOption
                        ;;
                "" )
                        : # Do nothing
                        ;;
                -[Hh] | --help | help )
                        readonly option_help="true" 2>/dev/null
                        ;;
                * )
                        readonly wrong_option="${option}" 2>/dev/null
                        ;;
        esac

done

case "${operation}" in
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
        restore )
                checkForWrongParameters
                checkRoot
                config
                restore
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
                readonly wrong_operation="${operation}"
                showUsage
                ;;
esac

printf "%bFinished successfully.%b\n" "${prefix_title}" "${prefix_reset}"

exit 0
