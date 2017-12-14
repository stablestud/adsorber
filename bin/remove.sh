#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:---   ---default value:---
# CRONTAB_DIR_PATH  /etc/cron.weekly
# REPLY_TO_PROMPT   Null (not set)
# SCRIPT_DIR_PATH   The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH  /etc/systemd/system

removeSystemd() {
    if [ -e "${SYSTEMD_DIR_PATH}/adsorber.service" ]; then
        systemctl stop adsorber.timer
        systemctl disable adsorber.timer
        #systemctl stop adsorber.service 2>/dev/null 1>&2
        #systemctl disable adsorber.server 2/dev/null 1>&2 # Is not enabled by default

        rm "${SYSTEMD_DIR_PATH}/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.service" \
            || {
                echo "Couldn't remove systemd service files." 1>&2
                return 1
        }
        
        systemctl daemon-reload
    else
        echo "Systemd service not installed. Skipping..." 1>&2
    fi

    return 0
}

removeCronjob() {
    if [ -e "${CRONTAB_DIR_PATH}/80adsorber" ]; then
        rm "${CRONTAB_DIR_PATH}/80adsorber" \
            && echo "Removed adsorber's cronjob."
    else
        echo "Cronjob not installed. Skipping..." 1>&2
    fi

    return 0
}

promptRemove() {
    if [ -z "${REPLY_TO_PROMPT}" ]; then
        read -p "Do you really want to remove adsorber? [Y/n] " REPLY_TO_PROMPT
    fi

    case "${REPLY_TO_PROMPT}" in
        [Yy] | [Yy][Ee][Ss] )
            return 0
            ;;
        * )
            echo "Remove cancelled." 1>&2
            exit 1
            ;;
    esac

    return 0
}

removeHostsFile() {
    if [ -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
        mv "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}" \
            && echo "Successfully restored ${HOSTS_FILE_PATH}"
    else
        echo "Can not restore hosts file. Original hosts file does not exist." 1>&2
        echo "Maybe already removed?" 1>&2
        exit 1
    fi

    return 0
}

removeCleanUp() {
    echo "Removing leftovers..."
    rm -rf "${TMP_DIR_PATH}" 2>/dev/null 1>&2

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
