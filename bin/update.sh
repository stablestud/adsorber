#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# BLACKLIST_FILE_PATH     SCRIPT_DIR_PATH/whitelist
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original
# REPLY_TO_FORCE_PROMPT   Null (not set)
# SCRIPT_DIR_PATH         The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCELIST_FILE_PATH    SCRIPT_DIR_PATH/sources.list (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH            /tmp/adsorber
# WHITELIST_FILE_PATH     SCRIPT_DIR_PATH/blacklist

updateCleanUp() {
  echo "Cleaning up..."
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

checkBackupExist() {
  if [ ! -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
    if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
      echo "Backup of ${HOSTS_FILE_PATH} does not exist. To backup run '${0} install'." 1>&2
      read -p "Ignore issue and continue? (May break your system, not recommended) [YES/n]: " REPLY_TO_FORCE_PROMPT
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

createTmpDir() {
  if [ ! -d ${TMP_DIR_PATH} ]; then
    mkdir "${TMP_DIR_PATH}"
  else
    echo "Removing previous tmp folder..."
    rm -rf "${TMP_DIR_PATH}"
    mkdir "${TMP_DIR_PATH}"
  fi
  return 0
}

readSourceList() {
  if [ ! -e "${SOURCELIST_FILE_PATH}" ]; then
    if [ ! -e "${BLACKLIST_FILE_PATH}" ]; then
      echo "Missing 'sources.list' and blacklist. To fix run '${0} install'." 1>&2
      exit 1
    fi
    return 1
  else
    SOURCELIST_FILE_CONTENT="$(sed -n '/^\s*http.*/p' "${SOURCELIST_FILE_PATH}" \
      | sed 's/\s\+#.*//g')"
    # Only read sources with http(s) at the beginning
    # Remove inline # comments
  fi
  return 0
}

fetchSources() {
  local total_count=0
  local successful_count=0
  local domain
  while read -r domain; do
    (( total_count++ ))
    echo "Getting: ${domain}"
    if [ $(type -fP curl) ]; then
      if curl "${domain}" --progress-bar -L --connect-timeout 30 --fail --retry 1 >> "${TMP_DIR_PATH}/fetched"; then
        (( successful_count++ ))
      else
        echo "curl couldn't fetch ${domain}" 1>&2
      fi
    elif [ $(type -fP wget) ]; then
      printf "wget: "
      if wget "${domain}" --show-progress -L --timeout=30 -t 1 -nv -O - >> "${TMP_DIR_PATH}/fetched"; then
        (( successful_count++ ))
      else
        echo "wget couldn't fetch ${domain}" 1>&2
      fi
    else
      echo "Neither curl nor wget installed. Can't continue." 1>&2
      updateCleanUp
      exit 2
    fi
  done <<< "${SOURCELIST_FILE_CONTENT}"
  if [ "${successful_count}" == 0 ]; then
    echo "Nothing to apply [${successful_count}/${total_count}]." 1>&2
    return 1
  else
    echo "Successfully fetched ${successful_count} out of ${total_count} hosts sources."
  fi
  return 0
}

readWhiteList() {
  if [ ! -e "${WHITELIST_FILE_PATH}" ]; then
    echo "Whitelist does not exist, ignoring..." 1>&2
    return 1
  else
    cat "${WHITELIST_FILE_PATH}" >> "${TMP_DIR_PATH}/whitelist"
    filterDomains "whitelist" "whitelist-filtered"
    sortDomains "whitelist-filtered" "whitelist-sorted"
  fi
  return 0
}

readBlackList() {
  if [ ! -e "${BLACKLIST_FILE_PATH}" ]; then
    echo "Blacklist does not exist, ignoring..." 1>&2
    return 1
  else
    cat "${BLACKLIST_FILE_PATH}" >> "${TMP_DIR_PATH}/blacklist"
    filterDomains "blacklist" "blacklist-filtered"
    sortDomains "blacklist-filtered" "blacklist-sorted"
  fi
  return 0
}

filterDomains() {
  local input_file="${1}"
  local output_file="${2}"
  cat "${TMP_DIR_PATH}/${input_file}" \
    | sed 's/\r/\n/g' \
    | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
    | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
    | sed 's/\s\+#.*//g' \
    | sed 's/[[:blank:]]\+/ /g' \
    | sed -n '/^0\.0\.0\.0\s.*\..*/p' \
    | sed -n '/\.local\s*$/!p' \
    > "${TMP_DIR_PATH}/${output_file}"
  # - replace OSX '\r' and MS-DOS '\r\n' with Unix '\n' (linebreak)
  # - replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
  # - only keep lines starting with 0.0.0.0
  # - remove inline '#' comments
  # - replace tabs and multiple spaces with one space
  # - remove domains without a dot (e.g localhost , loopback , ip6-allnodes , etc...)
  # - remove domains that are redirecting to *.local
  return 0
}

sortDomains() {
  # Sort the domains by alphabet and also remove duplicates
  local input_file="${1}"
  local output_file="${2}"
  sort "${TMP_DIR_PATH}/${input_file}" -f -u -o "${TMP_DIR_PATH}/${output_file}"
  return 0
}

mergeBlackList() {
  local input_file="${1}"
  if [ -s "${TMP_DIR_PATH}/blacklist-sorted" ]; then
    echo "Applying blacklist..."
    cat "${TMP_DIR_PATH}/cache" "${TMP_DIR_PATH}/blacklist-sorted" >> "${TMP_DIR_PATH}/merged-blacklist"
    filterDomains "merged-blacklist" "merged-blacklist-filtered"
    sortDomains "merged-blacklist-filtered" "merged-blacklist-sorted"
    cp "${TMP_DIR_PATH}/merged-blacklist-sorted" "${TMP_DIR_PATH}/cache"
  else
    return 1
  fi
  return 0
}

applyWhiteList() {
  local domain
  if [ -s "${TMP_DIR_PATH}/whitelist-sorted" ]; then
    echo "Applying whitelist..."
    sed -i 's/^0\.0\.0\.0\s\+//g' "${TMP_DIR_PATH}/whitelist-sorted"
    cp "${TMP_DIR_PATH}/cache" "${TMP_DIR_PATH}/applied-whitelist"
    while read -r domain; do
      sed -i "/.*${domain}$/d" "${TMP_DIR_PATH}/applied-whitelist"
    done < "${TMP_DIR_PATH}/whitelist-sorted"
    cp "${TMP_DIR_PATH}/applied-whitelist" "${TMP_DIR_PATH}/cache"
  else
    return 1
  fi
  return 0
}

preBuildHosts() {
  # Add hosts.header
  # Add hosts.original
  # Add hosts.title
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts_header" \
    | sed "s|@.\+@|${HOSTS_FILE_BACKUP_PATH}|g" > "${TMP_DIR_PATH}/hosts"
  # Add an empty line between comment and content
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${HOSTS_FILE_BACKUP_PATH}" >> "${TMP_DIR_PATH}/hosts" \
    || echo "You may want to add your hostname to ${HOSTS_FILE_PATH}"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts_title" >> "${TMP_DIR_PATH}/hosts"
}

buildHostsFile() {
  # Glue all pieces of the hosts file together
  echo "" >> "${TMP_DIR_PATH}/hosts"
  if [ -s "${TMP_DIR_PATH}/cache" ]; then
    cat "${TMP_DIR_PATH}/cache" >> "${TMP_DIR_PATH}/hosts"
  else
    echo "Nothing to apply. Exiting..." 1>&2
    updateCleanUp
    exit 1
  fi
  return 0
}

applyHostsFile() {
  # Replace systems hosts file with the modified version
  echo "Applying new hosts file...."
  cat "${TMP_DIR_PATH}/hosts" > "${HOSTS_FILE_PATH}" \
    || {
      echo "Couldn't apply hosts file. Aborting"
      buildCleanUp
      exit 1
  }
  echo "Successfully applied new hosts file."
  return 0
}
