#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# CRONTAB_DIR_PATH          /etc/cron.weekly
# HOSTS_FILE_PATH           /etc/hosts
# HOSTS_FILE_BACKUP_PATH    /etc/hosts.original
# REPLY_TO_FORCE_PROMPT     Null (not set)
# REPLY_TO_PROMPT           Null (not set)
# REPLY_TO_SCHEDULER_PROMPT Null (not set)
# SCRIPT_DIR_PATH           The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH          /etc/systemd/system

copySourceList() {
    if [ ! -e "${SCRIPT_DIR_PATH}/sources.list" ] || [ ! -s "${SCRIPT_DIR_PATH}/sources.list" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-sources.list" "${SCRIPT_DIR_PATH}/sources.list" \
            && echo "To add new host sources, please edit sources.list"
    fi

    return 0
}

copyWhiteList() {
    if [ ! -e "${SCRIPT_DIR_PATH}/whitelist" ] || [ ! -s "${SCRIPT_DIR_PATH}/whitelist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-whitelist" "${SCRIPT_DIR_PATH}/whitelist" \
            && echo "To allow host sources, please edit the whitelist."
    fi

    return 0
}

copyBlackList() {
    if [ ! -e "${SCRIPT_DIR_PATH}/blacklist" ] || [ ! -s "${SCRIPT_DIR_PATH}/blacklist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-blacklist" "${SCRIPT_DIR_PATH}/blacklist" \
            && echo "To block additional host sources, please edit the blacklist."
    fi

    return 0
}

backupHostsFile() {
    if [ ! -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
        cp "${HOSTS_FILE_PATH}" "${HOSTS_FILE_BACKUP_PATH}" \
            || echo "Successfully backed up ${HOSTS_FILE_PATH} to ${HOSTS_FILE_BACKUP_PATH}."
    else

        if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
            read -p "Backup of ${HOSTS_FILE_PATH} already exist. Continue? [YES/n]: " REPLY_TO_FORCE_PROMPT
        fi

        case "${REPLY_TO_FORCE_PROMPT}" in
            [Yy][Ee][Ss] )
                return 0
                ;;
            * )
                echo "Aborted." 1>&2
                exit 1
                ;;
        esac
    fi

    return 0
}

installCronjob() {
    echo "Installing cronjob..."

    cp "${SCRIPT_DIR_PATH}/bin/cron/80adsorber" "${CRONTAB_DIR_PATH}"

    sed -i "s|@.*|${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${CRONTAB_DIR_PATH}/80adsorber"
    # Replace the @ place holder line with SCRIPT_DIR_PATH

    return 0
}

installSystemd() {
    echo "Installing systemd service..."

    cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.service" "${SYSTEMD_DIR_PATH}/adsorber.service"
    sed -i "s|@ExecStart.*|ExecStart=${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SYSTEMD_DIR_PATH}/adsorber.service"
    # Replace the @ place holder line with SCRIPT_DIR_PATH
    cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.timer"

    systemctl daemon-reload \
        && systemctl enable adsorber.timer \
        && systemctl start adsorber.timer || echo "Couldn't start systemd service." 1>&2

    return 0
}

promptInstall() {
    if [ -z "${REPLY_TO_PROMPT}" ]; then
        read -p "Do you really want to install adsorber? [Y/n]: " REPLY_TO_PROMPT
    fi

    case "${REPLY_TO_PROMPT}" in
        [Yy] | [Yy][Ee][Ss] )
            return 0
            ;;
        * )
            echo "Installation cancelled." 1>&2
            exit 1
            ;;
    esac

    return 0
}

promptScheduler() {
    if [ -z "${REPLY_TO_SCHEDULER_PROMPT}" ]; then
        read -p "What scheduler should be used to update hosts file automatically? [(S)ystemd/(C)ron/(N)one]: " REPLY_TO_SCHEDULER_PROMPT
    fi

    case "${REPLY_TO_SCHEDULER_PROMPT}" in
        [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
            installSystemd
            ;;
        [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
            installCronjob
            ;;
        * )
            echo "Skipping scheduler creation..."
            ;;
    esac

    return 0
}

install() {
    echo "Installing Adsorber..."
    copySourceList
    copyWhiteList
    copyBlackList
    promptInstall
    backupHostsFile
    promptScheduler

    return 0
}
