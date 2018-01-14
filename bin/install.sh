#!/bin/bash

# Author:     stablestud <dev@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are defined in adsorber.conf or adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# CRONTAB_DIR_PATH          /etc/cron.weekly
# HOSTS_FILE_PATH           /etc/hosts
# HOSTS_FILE_BACKUP_PATH    /etc/hosts.original
# REPLY_TO_PROMPT           Null (not set)
# REPLY_TO_SCHEDULER_PROMPT Null (not set)
# SCRIPT_DIR_PATH           The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH          /etc/systemd/system


installCleanUp() {
    rm -rf "${TMP_DIR_PATH}"

    return 0
}


backupHostsFile() {
    if [ ! -f "${HOSTS_FILE_BACKUP_PATH}" ]; then
        cp "${HOSTS_FILE_PATH}" "${HOSTS_FILE_BACKUP_PATH}" \
            && echo -e "${PREFIX}Successfully backed up ${HOSTS_FILE_PATH} to ${HOSTS_FILE_BACKUP_PATH}."
    else
        echo -e "${PREFIX}Backup already exist, no need to backup."
    fi

    return 0
}


installCronjob() {
    echo -e "${PREFIX}Installing cronjob ..."

    if [ ! -d "${CRONTAB_DIR_PATH}" ]; then
        echo -e "! Wrong CRONTAB_DIR_PATH set. Can't access: ${CRONTAB_DIR_PATH}." 1>&2
        installCleanUp
        exit 1
    fi

    # Replace the @ place holder line with SCRIPT_DIR_PATH and copy the content to crons directory
    sed "s|@.*|${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SCRIPT_DIR_PATH}/bin/cron/80adsorber" > "${CRONTAB_DIR_PATH}/80adsorber"
    chmod u=rwx,g=rx,o=rx "${CRONTAB_DIR_PATH}/80adsorber"

    return 0
}


installSystemd() {
    echo -e "${PREFIX}Installing systemd service ..."

    if [ ! -d "${SYSTEMD_DIR_PATH}" ]; then
        echo -e "! Wrong SYSTEMD_DIR_PATH set. Can't access: ${SYSTEMD_DIR_PATH}."
        installCleanUp
        exit 1
    fi

    # Replace the @ place holder line with SCRIPT_DIR_PATH and copy to its systemd directory
    sed "s|@ExecStart.*|ExecStart=${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.service" > "${SYSTEMD_DIR_PATH}/adsorber.service"
    cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.timer"

    chmod u=rwx,g=rx,o=rx "${SYSTEMD_DIR_PATH}/adsorber.service" "${SYSTEMD_DIR_PATH}/adsorber.timer"

    printf "${PREFIX}"
    systemctl daemon-reload \
        && systemctl enable adsorber.timer \
        && systemctl start adsorber.timer || echo -e "${PREFIX_WARNING}Couldn't start systemd service." 1>&2

    return 0
}


promptInstall() {
    if [ -z "${REPLY_TO_PROMPT}" ]; then
        read -p "${PREFIX_INPUT}Do you really want to install Adsorber? [Y/n]: " REPLY_TO_PROMPT
    fi

    case "${REPLY_TO_PROMPT}" in
        [Yy] | [Yy][Ee][Ss] )
            return 0
            ;;
        * )
            echo -e "${PREFIX_WARNING}Installation cancelled." 1>&2
            installCleanUp
            exit 1
            ;;
    esac

    return 0
}


promptScheduler() {
    if [ -z "${REPLY_TO_SCHEDULER_PROMPT}" ]; then
        read -p "${PREFIX_INPUT}What scheduler should be used to update hosts file automatically? [(S)ystemd/(C)ron/(N)one]: " REPLY_TO_SCHEDULER_PROMPT
    fi

    case "${REPLY_TO_SCHEDULER_PROMPT}" in
        [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
            installSystemd
            ;;
        [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
            installCronjob
            ;;
        * )
            echo -e "${PREFIX}Skipping scheduler creation ..."
            ;;
    esac

    return 0
}


install() {
    echo -e "${BWHITE}Installing Adsorber ...${COLOUR_RESET}"
    promptInstall
    backupHostsFile
    promptScheduler

    return 0
}
