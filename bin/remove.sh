#!/bin/bash

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------     ---default value:----   ---defined in:--------------
# BACKEDUP                Null (not set)          bin/install.sh
# CRONTAB_DIR_PATH        /etc/cron.weekly        bin/config.sh, adsorber.conf
# COLOUR_RESET            \033[0m                 bin/colours.sh
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original     bin/config.sh, adsorber.conf
# INSTALLED_SCHEDULER     Null (not set)          bin/install.sh
# PREFIX                  '  ' (two spaces)       bin/colours.sh
# PREFIX_INPUT            '  ' (two spaces)       bin/colours.sh
# PREFIX_TITLE            \033[1;37m              bin/colours.sh
# PREFIX_WARNING          '- '                    bin/colours.sh
# REPLY_TO_PROMPT         Null (not set)          bin/install.sh, adsorber.sh
# SCRIPT_DIR_PATH         script root directory   adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH        /etc/systemd/system     bin/config.sh, adsorber.conf


errorCleanUp()
{
        echo "${PREFIX_WARNING}Cleaning up ..."

        # Remove scheduler if installed in the same run
        case "${INSTALLED_SCHEDULER}" in
                cronjob )
                        remove::Cronjob
                        ;;
                systemd )
                        remove::Systemd
                        ;;
        esac

        if [ "${BACKEDUP}" == "true" ]; then
                rm -f "${HOSTS_FILE_BACKUP_PATH}"
        fi

        rm -rf "${TMP_DIR_PATH}" 2>/dev/null 1>&2

        return 0
}


cleanUp()
{
        echo "${PREFIX}Cleaning up ..."

        rm -rf "${TMP_DIR_PATH}" 2>/dev/null 1>&2

        return 0
}


remove::Systemd()
{
        if [ -f "${SYSTEMD_DIR_PATH}/adsorber.service" ] || [ -f "${SYSTEMD_DIR_PATH}/adsorber.timer" ]; then

                systemctl stop adsorber.timer 2>/dev/null
                systemctl disable adsorber.timer | ( printf "%s" "${PREFIX}" && cat )
                systemctl stop adsorber.service 2>/dev/null 1>&2
                systemctl disable adsorber.service 2>/dev/null 1>&2 # The service is not enabled by default

                rm "${SYSTEMD_DIR_PATH}/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.service" \
                        || {
                                echo -e "${PREFIX_WARNING}Couldn't remove systemd service files at ${SYSTEMD_DIR_PATH}." 1>&2
                                return 1
                        }

                systemctl daemon-reload
        else
                echo "${PREFIX}Systemd service not installed. Skipping ..." 1>&2
        fi

        return 0
}


remove::Cronjob()
{
        if [ -f "${CRONTAB_DIR_PATH}/80adsorber" ]; then
                rm "${CRONTAB_DIR_PATH}/80adsorber" \
                        && echo "${PREFIX}Removed Adsorber's cronjob."
        else
                echo "${PREFIX}Cronjob not installed. Skipping ..." 1>&2
        fi

        return 0
}


remove::Prompt()
{
        if [ -z "${REPLY_TO_PROMPT}" ]; then
                read -r -p "${PREFIX_INPUT}Do you really want to remove Adsorber? [Y/n] " REPLY_TO_PROMPT
        fi

        case "${REPLY_TO_PROMPT}" in
                [Yy] | [Yy][Ee][Ss] )
                        return 0
                        ;;
                * )
                        echo -e "${PREFIX_WARNING}Remove cancelled." 1>&2
                        errorCleanUp
                        exit 130
                        ;;
        esac

        return 0
}


remove::HostsFile()
{
        if [ -f "${HOSTS_FILE_BACKUP_PATH}" ]; then
                mv "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}" \
                        && echo "${PREFIX}Successfully restored ${HOSTS_FILE_PATH}"
        else
                echo -e "${PREFIX_FATAL}Can not restore hosts file. Original hosts file does not exist.${COLOUR_RESET}" 1>&2
                echo "${PREFIX}Maybe already removed?" 1>&2
                errorCleanUp
                exit 1
        fi

        return 0
}


remove()
{
        echo -e "${PREFIX_TITLE}Removing Adsorber ...${COLOUR_RESET}"
        remove::Prompt
        remove::Systemd
        remove::Cronjob
        remove::HostsFile
        cleanUp

        return 0
}
