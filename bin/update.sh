#!/bin/bash

# Author:     stablestud <dev@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are defined in adsorber.sh or adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original
# PRIMARY_LIST            blacklist
# REPLY_TO_FORCE_PROMPT   Null (not set)
# COLOUR_RESET
# SCRIPT_DIR_PATH         The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCELIST_FILE_PATH    SCRIPT_DIR_PATH/sources.list (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH            /tmp/adsorber
# USE_PARTIAL_MATCHING    true


updateCleanUp() {
    echo -e "${PREFIX}Cleaning up ..."

    rm -rf "${TMP_DIR_PATH}" 2>/dev/null 1>&2

    return 0
}


checkBackupExist() {
    if [ ! -f "${HOSTS_FILE_BACKUP_PATH}" ]; then

        if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
            echo -e "${PREFIX_FATAL}Backup of ${HOSTS_FILE_PATH} does not exist. To backup run '${0} install'.${COLOUR_RESET}" 1>&2
            read -p "${PREFIX_INPUT}Ignore issue and continue? (May break your system, not recommended) [YES/n]: " REPLY_TO_FORCE_PROMPT
        fi

        case "${REPLY_TO_FORCE_PROMPT}" in
            [Yy][Ee][Ss] )
                return 0
                ;;
            * )
                echo -e "${PREFIX_WARNING}Aborted." 1>&2
                updateCleanUp
                exit 1
                ;;
        esac
    fi

    return 0
}


createTmpDir() {
    if [ ! -d "${TMP_DIR_PATH}" ]; then
        mkdir "${TMP_DIR_PATH}"
    elif [ ! -s "${TMP_DIR_PATH}/config-filtered" ]; then
        echo -e "${PREFIX}Removing previous tmp folder ..."
        rm -rf "${TMP_DIR_PATH}"
        mkdir "${TMP_DIR_PATH}"
    fi

    return 0
}


readSourceList() {
    if [ ! -s "${SOURCELIST_FILE_PATH}" ]; then

        if [ ! -s "${SCRIPT_DIR_PATH}/blacklist" ]; then
            echo -e "${PREFIX_FATAL}Missing 'sources.list' and blacklist. To fix run '${0} install'.${COLOUR_RESET}" 1>&2
            exit 1
        fi

        echo -e "${PREFIX}No sources to fetch from, ignoring ..."
        return 1
    else
        # Only read sources with http(s) at the beginning
        # Remove inline # comments
        cat "${SOURCELIST_FILE_PATH}" \
            | sed -n '/^\s*http.*/p' \
            | sed 's/\s\+#.*//g' \
            > "${TMP_DIR_PATH}/sourceslist-filtered"

        if [ ! -s "${TMP_DIR_PATH}/sourceslist-filtered" ]; then
            echo -e "${PREFIX}No hosts set in sources.list, ignoring ..."
            return 1
        fi

    fi

    return 0
}


readWhiteList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/whitelist" ]; then
        echo -e "${PREFIX}Whitelist does not exist, ignoring ..." 1>&2
        return 1
    else
        cp "${SCRIPT_DIR_PATH}/whitelist" "${TMP_DIR_PATH}/whitelist"

        filterDomains "whitelist" "whitelist-filtered"
        sortDomains "whitelist-filtered" "whitelist-sorted"
    fi

    return 0
}


readBlackList() {
    if [ ! -f "${SCRIPT_DIR_PATH}/blacklist" ]; then
        echo -e "${PREFIX}Blacklist does not exist, ignoring ..." 1>&2
        return 1
    else
        cp "${SCRIPT_DIR_PATH}/blacklist" "${TMP_DIR_PATH}/blacklist"

        filterDomains "blacklist" "blacklist-filtered"
        sortDomains "blacklist-filtered" "blacklist-sorted"
    fi

    return 0
}


fetchSources() {
    local total_count=0
    local successful_count=0
    local domain

    while read -r domain; do
        (( total_count++ ))
        echo -e "${PREFIX}${IWHITE}Getting${COLOUR_RESET}: ${domain}"

        if [ $(type -fP wget) ]; then
            printf "${PREFIX}"

            if wget "${domain}" --show-progress -L --timeout=30 -t 1 -nv -O - >> "${TMP_DIR_PATH}/fetched"; then
                (( successful_count++ ))
            else
                echo -e "${PREFIX_WARNING}wget couldn't fetch: ${domain}" 1>&2
            fi
        elif [ $(type -fP curl) ]; then
            printf "${PREFIX}"
            if curl "${domain}" --progress-bar -L --connect-timeout 30 --fail --retry 1 >> "${TMP_DIR_PATH}/fetched"; then
                (( successful_count++ ))
            else
                echo -e "${PREFIX_WARNING}Curl couldn't fetch ${domain}" 1>&2
            fi
        else
            echo -e "${PREFIX_FATAL}Neither curl nor wget installed. Can't continue.${COLOUR_RESET}" 1>&2
            updateCleanUp
            exit 2
        fi

    done < "${TMP_DIR_PATH}/sourceslist-filtered"

    if [ "${successful_count}" -eq 0 ]; then
        echo -e "${PREFIX_WARNING}Nothing to apply [${successful_count}/${total_count}]." 1>&2
        return 1
    else
        echo -e "${PREFIX}${IWHITE}Successfully fetched ${BWHITE}${successful_count} out of ${total_count}${IWHITE} hosts sources.${COLOUR_RESET}"
    fi

    return 0
}


filterDomains() {
    local input_file="${1}"
    local output_file="${2}"

    # - replace OSX '\r' and MS-DOS '\r\n' with Unix '\n' (linebreak)
    # - replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
    # - only keep lines starting with 0.0.0.0
    # - remove inline '#' comments
    # - replace tabs and multiple spaces with one space
    # - remove domains without a dot (e.g localhost , loopback , ip6-allnodes , etc...)
    # - remove domains that are redirecting to *.local
    cat "${TMP_DIR_PATH}/${input_file}" \
        | sed 's/\r/\n/g' \
        | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
        | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
        | sed 's/\s\+#.*//g' \
        | sed 's/[[:blank:]]\+/ /g' \
        | sed -n '/^0\.0\.0\.0\s.\+\..\+/p' \
        | sed -n '/\.local\s*$/!p' \
        > "${TMP_DIR_PATH}/${output_file}"

    return 0
}


sortDomains() {
    local input_file="${1}"
    local output_file="${2}"

    # Sort the domains by alphabet and also remove duplicates
    sort "${TMP_DIR_PATH}/${input_file}" -f -u -o "${TMP_DIR_PATH}/${output_file}"

    return 0
}


applyWhiteList() {
    local domain

    if [ ! -s "${TMP_DIR_PATH}/whitelist-sorted" ]; then
        echo -e "${PREFIX}Whitelist is empty, ignoring ..."
        return 1
    else
        echo -e "${PREFIX}Applying whitelist ..."

        sed -i 's/^0\.0\.0\.0\s\+//g' "${TMP_DIR_PATH}/whitelist-sorted"
        cp "${TMP_DIR_PATH}/cache" "${TMP_DIR_PATH}/applied-whitelist"

        while read -r domain; do

            if [ "${USE_PARTIAL_MATCHING}" == "true" ]; then
                sed -i "/\.*${domain}$/d" "${TMP_DIR_PATH}/applied-whitelist"
            elif [ "${USE_PARTIAL_MATCHING}" == "false" ]; then
                sed -i "/\s\+${domain}$/d" "${TMP_DIR_PATH}/applied-whitelist"
            else
                echo -e "${PREFIX_FATAL}Wrong USE_PARTIAL_MATCHING set, either set it to 'true' or 'false'.${COLOUR_RESET}" 1>&2
                updateCleanUp
                exit 1
            fi

        done < "${TMP_DIR_PATH}/whitelist-sorted"

        cp "${TMP_DIR_PATH}/applied-whitelist" "${TMP_DIR_PATH}/cache"
    fi

    return 0
}


mergeBlackList() {
    local input_file="${1}"

    if [ ! -s "${TMP_DIR_PATH}/blacklist-sorted" ]; then
        echo -e "${PREFIX}Blacklist is empty, ignoring ..."
        return 1
    else
        echo -e "${PREFIX}Applying blacklist ..."

        cat "${TMP_DIR_PATH}/cache" "${TMP_DIR_PATH}/blacklist-sorted" >> "${TMP_DIR_PATH}/merged-blacklist"

        filterDomains "merged-blacklist" "merged-blacklist-filtered"
        sortDomains "merged-blacklist-filtered" "merged-blacklist-sorted"

        cp "${TMP_DIR_PATH}/merged-blacklist-sorted" "${TMP_DIR_PATH}/cache"
    fi

    return 0
}


isCacheEmpty() {
    if [ -s "${TMP_DIR_PATH}/cache" ]; then
        return 0
    else
        echo -e "${PREFIX_WARNING}Nothing to apply." 1>&2
        updateCleanUp
        exit 1
    fi

    return 0
}


preBuildHosts() {
    # Replace @...@ with the path to the backup hosts
    sed "s|@.\+@|${HOSTS_FILE_BACKUP_PATH}|g" "${SCRIPT_DIR_PATH}/bin/components/hosts_header" > "${TMP_DIR_PATH}/hosts"

    echo -e "" >> "${TMP_DIR_PATH}/hosts"

    # Add hosts.original
    cat "${HOSTS_FILE_BACKUP_PATH}" >> "${TMP_DIR_PATH}/hosts" \
        || echo -e "${PREFIX}You may want to add your hostname to ${HOSTS_FILE_PATH}" 1>&2

    echo -e "" >> "${TMP_DIR_PATH}/hosts"

    # Add hosts_title
    cat "${SCRIPT_DIR_PATH}/bin/components/hosts_title" >> "${TMP_DIR_PATH}/hosts"

    return 0
}


buildHostsFile() {
    echo -e "" >> "${TMP_DIR_PATH}/hosts"

    # Add ad-domains to the hosts file
    cat "${TMP_DIR_PATH}/cache" >> "${TMP_DIR_PATH}/hosts"

    echo -e "" >> "${TMP_DIR_PATH}/hosts"

    sed "s|@.\+@|${HOSTS_FILE_BACKUP_PATH}|g" "${SCRIPT_DIR_PATH}/bin/components/hosts_header" >> "${TMP_DIR_PATH}/hosts"

    return 0
}


countBlockedDomains() {
    readonly COUNT_BLOCKED="$(cat ${TMP_DIR_PATH}/cache | wc -l)"
    return 0
}


applyHostsFile() {
    echo -e "${PREFIX}Applying new hosts file ..."

    # Replace systems hosts file with the modified version
    cat "${TMP_DIR_PATH}/hosts" > "${HOSTS_FILE_PATH}" \
        || {
            echo -e "${PREFIX_FATAL}Couldn't apply hosts file. Aborting.${COLOUR_RESET}" 1>&2
            updateCleanUp
            exit 1
    }

    echo -e "${PREFIX}${IWHITE}Successfully applied new hosts file with ${BWHITE}${COUNT_BLOCKED} ${IWHITE}blocked domains.${COLOUR_RESET}"

    return 0
}


update() {
    echo -e "${BWHITE}Updating ${HOSTS_FILE_PATH} ...${COLOUR_RESET}"

    checkBackupExist
    createTmpDir
    readBlackList
    readWhiteList

    if readSourceList; then
        fetchSources
        filterDomains "fetched" "fetched-filtered"
        sortDomains "fetched-filtered" "fetched-sorted"

        cp "${TMP_DIR_PATH}/fetched-sorted" "${TMP_DIR_PATH}/cache"
    else
        # Create empty cache file
        printf "" >> "${TMP_DIR_PATH}/cache"
    fi

    case "${PRIMARY_LIST}" in
        whitelist )
            mergeBlackList
            applyWhiteList
            ;;
        blacklist )
            applyWhiteList
            mergeBlackList
            ;;
        * )
            echo -e "${PREFIX_FATAL}Wrong PRIMARY_LIST set in adsorber.conf. Choose either 'whitelist' or 'blacklist'${COLOUR_RESET}" 1>&2
            updateCleanUp
            exit 1
            ;;
    esac

    isCacheEmpty
    preBuildHosts
    buildHostsFile
    countBlockedDomains
    applyHostsFile
    updateCleanUp

    return 0
}
