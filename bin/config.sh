#!/bin/bash

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared in adsorber.conf, adsorber.sh or bin/config.sh.
# If you run this file independently following variables need to be set:
# ---variable:--------   ---default value:------------   ----declared in:------------
# COLOUR_RESET           \033[0m                         bin/colours.sh
# PREFIX                 '  ' (two spaces)               bin/colours.sh
# PREFIX_TITLE           \033[1;37m                      bin/colours.sh
# PREFIX_WARNING         '- '                            bin/colours.sh
# PRIMARY_LIST           blacklist                       bin/config.sh, adsorber.conf
# SCRIPT_DIR_PATH        script root directory           adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# SOURCELIST_FILE_PATH   SCRIPT_DIR_PATH/sources.list    adsorber.sh
#   (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH           /tmp/adsorber                   adsorber.sh
# USE_PARTIAL_MATCHING   true                            bin/config.sh, adsorber.conf
# VERSION                0.2.2 or similar                adsorber.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to emulated:
# ---function:-----  ---function defined in:---
# cleanUp            bin/remove.sh
# errorCleanUp       bin/remove.sh


SETTING_STRING[0]="PRIMARY_LIST"
SETTING_STRING[1]="USE_PARTIAL_MATCHING"
SETTING_STRING[2]="IGNORE_DOWNLOAD_ERROR"
SETTING_STRING[3]="HOSTS_FILE_PATH"
SETTING_STRING[4]="HOSTS_FILE_BACKUP_PATH"
SETTING_STRING[5]="CRONTAB_DIR_PATH"
SETTING_STRING[6]="SYSTEMD_DIR_PATH"

readonly SETTING_STRING


configCreateTmpDir() {
    if [ ! -d ${TMP_DIR_PATH} ]; then
        mkdir "${TMP_DIR_PATH}"
    else
        echo "${PREFIX}Removing previous tmp folder ..."
        rm -rf "${TMP_DIR_PATH}"
        mkdir "${TMP_DIR_PATH}"
    fi

    return 0
}


copySourceList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/sources.list" ] || [ ! -s "${SCRIPT_DIR_PATH}/sources.list" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-sources.list" "${SCRIPT_DIR_PATH}/sources.list" \
            && echo "${PREFIX}Created sources.list: to add new host sources edit this file."
    fi

    return 0
}


copyWhiteList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/whitelist" ] || [ ! -s "${SCRIPT_DIR_PATH}/whitelist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-whitelist" "${SCRIPT_DIR_PATH}/whitelist" \
            && echo "${PREFIX}Created whitelist: to allow specific domains edit this file."
    fi

    return 0
}


copyBlackList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/blacklist" ] || [ ! -s "${SCRIPT_DIR_PATH}/blacklist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-blacklist" "${SCRIPT_DIR_PATH}/blacklist" \
            && echo "${PREFIX}Created blacklist: to block additional domains edit this file."
    fi

    return 0
}


copyConfig() {
    if [ -s "${SCRIPT_DIR_PATH}/adsorber.conf" ]; then
        cp "${SCRIPT_DIR_PATH}/adsorber.conf" "${TMP_DIR_PATH}/config"
    else
        echo -e "${PREFIX_FATAL}No config file found. Creating default.${COLOUR_RESET}" 1>&2
        echo "${PREFIX}Please re-run the command to continue."
        sed "s|@.*|# Config file for Adsorber v${VERSION}|g" "${SCRIPT_DIR_PATH}/bin/default/default-adsorber.conf" > "${SCRIPT_DIR_PATH}/adsorber.conf"

        errorCleanUp
        exit 126
    fi

    return 0
}


filterConfig() {
    local i

    for i in "${SETTING_STRING[@]}"; do
        # keep only lines starting with value out of SETTING_STRING
        sed -n "/^${i}/p" "${TMP_DIR_PATH}/config" \
            >> "${TMP_DIR_PATH}/config-filtered"
    done

    return 0
}


readConfig() {
    local line

    while read -r line; do
        readonly "${line}"
    done < "${TMP_DIR_PATH}/config-filtered"

    return 0
}


isVariableSet() {
    if [ -z "${HOSTS_FILE_PATH}" ] || [ -z "${HOSTS_FILE_BACKUP_PATH}" ] || [ -z "${CRONTAB_DIR_PATH}" ] || [ -z "${SYSTEMD_DIR_PATH}" ]; then
        echo -e "${PREFIX_FATAL}Missing setting(s) in adsorber.conf." 1>&2
        echo "${PREFIX}Please delete adsorber.conf and run '${0} install' to create a new config file." 1>&2
        errorCleanUp
        exit 127
    fi

    if [ -z "${PRIMARY_LIST}" ]; then
        echo -e "${PREFIX_WARNING}PRIMARY_LIST not set in adsorber.conf. Using default value: blacklist" 1>&2
        readonly PRIMARY_LIST="blacklist"
    fi

    if [ -z "${USE_PARTIAL_MATCHING}" ]; then
        echo -e "${PREFIX_WARNING}USE_PARTIAL_MATCHING not set in adsorber.conf. Using default value: true" 1>&2
        readonly USE_PARTIAL_MATCHING="true"
    fi

    if [ -z "${IGNORE_DOWNLOAD_ERROR}" ]; then
        echo -e "${PREFIX_WARNING}IGNORE_DOWNLOAD_ERROR not set in adsorber.conf. Using default value: false" 1>&2
        readonly IGNORE_DOWNLOAD_ERROR="false"
    fi

    return 0
}

isVariableValid() {
    if [ ! -f "${HOSTS_FILE_PATH}" ]; then
        echo -e "${PREFIX_FATAL}Wrong HOSTS_FILE_PATH set in adsorber.conf. Can't access: ${HOSTS_FILE_PATH}" 1>&2
        errorCleanUp
        exit 126
    fi

    return 0
}

printVariables() {
    echo -e "  - PRIMARY_LIST: ${PRIMARY_LIST}"
    echo -e "  - USE_PARTIAL_MATCHING: ${USE_PARTIAL_MATCHING}"
    echo -e "  - HOSTS_FILE_PATH:: ${HOSTS_FILE_PATH}"
    echo -e "  - HOSTS_FILE_BACKUP_PATH: ${HOSTS_FILE_BACKUP_PATH}"
    echo -e "  - CRONTAB_DIR_PATH: ${CRONTAB_DIR_PATH}"
    echo -e "  - SYSTEMD_DIR_PATH: ${SYSTEMD_DIR_PATH}"
    echo -e "  - TMP_DIR_PATH: ${TMP_DIR_PATH}"
    echo -e "  - SCRIPT_DIR_PATH: ${SCRIPT_DIR_PATH}"

    return 0
}


config() {
    echo -e "${PREFIX_TITLE}Reading configuration ... ${COLOUR_RESET}"
    configCreateTmpDir
    copySourceList
    copyWhiteList
    copyBlackList
    copyConfig
    filterConfig
    readConfig
    isVariableSet
    isVariableValid
    #printVariables # used for debugging
    return 0
}
