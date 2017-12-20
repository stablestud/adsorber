#!/bin/bash

# The following variables are defined in adsorber.sh or adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# PRIMARY_LIST            blacklist
# SCRIPT_DIR_PATH         The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCELIST_FILE_PATH    SCRIPT_DIR_PATH/sources.list (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH            /tmp/adsorber
# USE_PARTIAL_MATCHING    true

SETTING_STRING+=("PRIMARY_LIST")
SETTING_STRING+=("USE_PARTIAL_MATCHING")
SETTING_STRING+=("HOSTS_FILE_PATH")
SETTING_STRING+=("HOSTS_FILE_BACKUP_PATH")
SETTING_STRING+=("CRONTAB_DIR_PATH")
SETTING_STRING+=("SYSTEMD_DIR_PATH")

readonly SETTING_STRING


configCleanUp() {
    rm -rf "${TMP_DIR_PATH}"

    return 0
}


configCreateTmpDir() {
    if [ ! -d ${TMP_DIR_PATH} ]; then
        mkdir "${TMP_DIR_PATH}"
    else
        #echo "Removing previous tmp folder..."
        rm -rf "${TMP_DIR_PATH}"
        mkdir "${TMP_DIR_PATH}"
    fi

    return 0
}


copySourceList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/sources.list" ] || [ ! -s "${SCRIPT_DIR_PATH}/sources.list" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-sources.list" "${SCRIPT_DIR_PATH}/sources.list" \
            && echo "To add new host sources, please edit sources.list"
    fi

    return 0
}


copyWhiteList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/whitelist" ] || [ ! -s "${SCRIPT_DIR_PATH}/whitelist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-whitelist" "${SCRIPT_DIR_PATH}/whitelist" \
            && echo "To allow host sources, please edit the whitelist."
    fi

    return 0
}


copyBlackList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/blacklist" ] || [ ! -s "${SCRIPT_DIR_PATH}/blacklist" ]; then
        cp "${SCRIPT_DIR_PATH}/bin/default/default-blacklist" "${SCRIPT_DIR_PATH}/blacklist" \
            && echo "To block additional host sources, please edit the blacklist."
    fi

    return 0
}


copyConfig() {
    if [ -s "${SCRIPT_DIR_PATH}/adsorber.conf" ]; then
        cp "${SCRIPT_DIR_PATH}/adsorber.conf" "${TMP_DIR_PATH}/config"
    else
        echo "No config file found. Creating default."
        echo "Please re-run the command to continue."
        cp "${SCRIPT_DIR_PATH}/bin/default/default-adsorber.conf" "${SCRIPT_DIR_PATH}/adsorber.conf"
        configCleanUp
        exit 1
    fi

    return 0
}


filterConfig() {
    local i

    for i in "${SETTING_STRING[@]}"; do
        # keep only lines starting with value out of SETTING_STRING
        # remove characters after SETTING="..."
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
        echo "Missing settings in adsorber.conf" 1>&2
        echo "Please delete adsorber.conf and run '${0} install' to create a new config file." 1>&2
        configCleanUp
        exit 1
    fi

    if [ -z "${PRIMARY_LIST}" ]; then
        echo "PRIMARY_LIST not set in adsorber.conf. Using default value: 'blacklist'" 1>&2
        readonly PRIMARY_LIST="blacklist"
    fi

    if [ -z "${USE_PARTIAL_MATCHING}" ]; then
        echo "USE_PARTIAL_MATCHING not set in adsorber.conf. Using default value: 'true'" 1>&2
        readonly USE_PARTIAL_MATCHING="true"
    fi

    return 0
}

isVariableValid() {
    if [ ! -f "${HOSTS_FILE_PATH}" ]; then
        echo "Wrong HOSTS_FILE_PATH set. Can't access ${HOSTS_FILE_PATH}" 1>&2
    fi

    return 0
}

printVariables() {
    echo "${PRIMARY_LIST}"
    echo "${USE_PARTIAL_MATCHING}"
    echo "${HOSTS_FILE_PATH}"
    echo "${HOSTS_FILE_BACKUP_PATH}"
    echo "${CRONTAB_DIR_PATH}"
    echo "${SYSTEMD_DIR_PATH}"
    echo "${TMP_DIR_PATH}"
    echo "${SCRIPT_DIR_PATH}"

    return 0
}


config() {
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
