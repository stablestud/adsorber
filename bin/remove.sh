#!/bin/bash

# Author:     stablestud <dev@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are defined in adsorber.conf or adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:---   ---default value:---
# CRONTAB_DIR_PATH  /etc/cron.weekly
# REPLY_TO_PROMPT   Null (not set)
# SCRIPT_DIR_PATH   The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH  /etc/systemd/system


removeSystemd() {
    if [ -f "${SYSTEMD_DIR_PATH}/adsorber.service" ]; then
        printf "${PREFIX}"
        systemctl stop adsorber.timer
        systemctl disable adsorber.timer
        #systemctl stop adsorber.service 2>/dev/null 1>&2
        #systemctl disable adsorber.server 2/dev/null 1>&2 # Is not enabled by default

        rm "${SYSTEMD_DIR_PATH}/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.service" \
            || {
                echo -e "${PREFIX_WARNING}Couldn't remove systemd service files." 1>&2
                return 1
        }

        systemctl daemon-reload
    else
        echo -e "${PREFIX}Systemd service not installed. Skipping ..." 1>&2
    fi

    return 0
}


removeCronjob() {
    if [ -f "${CRONTAB_DIR_PATH}/80adsorber" ]; then
        rm "${CRONTAB_DIR_PATH}/80adsorber" \
            && echo -e "${PREFIX}Removed adsorber's cronjob."
    else
        echo -e "${PREFIX}Cronjob not installed. Skipping ..." 1>&2
    fi

    return 0
}


promptRemove() {
    if [ -z "${REPLY_TO_PROMPT}" ]; then
        read -p "${PREFIX_INPUT}Do you really want to remove adsorber? [Y/n] " REPLY_TO_PROMPT
    fi

    case "${REPLY_TO_PROMPT}" in
        [Yy] | [Yy][Ee][Ss] )
            return 0
            ;;
        * )
            echo -e "${PREFIX_WARNING}Remove cancelled." 1>&2
            exit 1
            ;;
    esac

    return 0
}


removeHostsFile() {
    if [ -f "${HOSTS_FILE_BACKUP_PATH}" ]; then
        mv "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}" \
            && echo -e "${PREFIX}Successfully restored ${HOSTS_FILE_PATH}"
    else
        echo -e "${PREFIX_WARNING}Can not restore hosts file. Original hosts file does not exist." 1>&2
        echo -e "${PREFIX}Maybe already removed?" 1>&2
        exit 1
    fi

    return 0
}


removeCleanUp() {
    echo -e "${PREFIX}Removing leftovers ..."
    rm -rf "${TMP_DIR_PATH}" 2>/dev/null 1>&2

    return 0
}


remove() {
    echo -e "${BWHITE}Removing Adsorber ...${COLOUR_RESET}"
    promptRemove
    removeSystemd
    removeCronjob
    removeHostsFile
    removeCleanUp

    return 0
}
