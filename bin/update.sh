#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original
# REPLY_TO_FORCE_PROMPT   Null (not set)
# SCRIPT_DIR_PATH         The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCES_FILE_PATH       SCRIPT_DIR_PATH/sources.list (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH            /tmp/adsorber


cleanUp() {
  echo "Cleaning up..."
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

checkBackupExist() {
  if [ -e "${HOSTS_FILE_BACKUP_PATH}" ]; then
    : # Do nothing
  else
    if [ -z "${REPLY_TO_FORCE_PROMPT}" ]; then
      echo "Backup of ${HOSTS_FILE_PATH} does not exist. To backup run '${0} install'." 1>&2
      read -p "Ignore issue and continue? May break your system. (Not recommended) [YES/n] " REPLY_TO_FORCE_PROMPT
    fi
    case "${REPLY_TO_FORCE_PROMPT}" in
      [Yy][Ee][Ss] )
        :
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
    echo "Removing previous tmp folder."
    rm -rf "${TMP_DIR_PATH}"
    mkdir "${TMP_DIR_PATH}"
  fi
  return 0
}

copySourceList() {
  if [ ! -e "${SCRIPT_DIR_PATH}/sources.list" ]; then
    cp "${SCRIPT_DIR_PATH}/bin/default/default-sources.list" "${SCRIPT_DIR_PATH}/sources.list" \
    && echo "To add new host sources, please edit sources.list"
  fi
  return 0
}

readSourceFile() {
  if [ ! -s "${SOURCES_FILE_PATH}" ]; then
    echo "Run '${0} install' first." 1>&2
    cleanUp
    exit 1
  else
    SOURCE_FILE_CONTENT="$(sed -n '/^\s*http.*/p' "${SOURCES_FILE_PATH}")"
    # Only read sources with http(s) at the beginning
    SOURCE_FILE_CONTENT="$(sed 's/\s\+#.*//g' <<< "${SOURCE_FILE_CONTENT}")"
    # Remove inline # comments
  fi
  return 0
}

fetchSources() {
  while read -r DOMAIN; do
    echo "Getting: ${DOMAIN}"
    if [ $(type -fP curl) ]; then
      curl "${DOMAIN}" --progress-bar -L --connect-timeout 30 --fail --retry 1 \
      >> "${TMP_DIR_PATH}/hosts.fetched" || echo "curl couldn't fetch ${DOMAIN}" 1>&2
    elif [ $(type -fP wget) ]; then
      printf "wget: "
      wget "${DOMAIN}" --show-progress -L --timeout=30 -t 1 -nv -O - \
      >> "${TMP_DIR_PATH}/hosts.fetched" || echo "wget couldn't fetch ${DOMAIN}" 1>&2
    else
      echo "Neither curl nor wget installed. Can't continue." 1>&2
      cleanUp
      exit 2
    fi
  done <<< "${SOURCE_FILE_CONTENT}"
  return 0
}

filterDomains() {
  cat "${TMP_DIR_PATH}/hosts.fetched" \
  | sed 's/\r/\n/g' \
  | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
  | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
  | sed 's/\s\+#.*//g' \
  | sed 's/[[:blank:]]\+/ /g' \
  | sed -n '/^0\.0\.0\.0\s.*\..*/p' \
  | sed -n '/\.local\s*$/!p' \
  >> "${TMP_DIR_PATH}/hosts.filtered"
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
  sort "${TMP_DIR_PATH}/hosts.filtered" -f -u -o "${TMP_DIR_PATH}/hosts.sorted"
  return 0
}

buildHostsFile() {
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts.header" | sed "s|@.\+@|${HOSTS_FILE_BACKUP_PATH}|g" >> "${TMP_DIR_PATH}/hosts"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${HOSTS_FILE_BACKUP_PATH}" >> "${TMP_DIR_PATH}/hosts" 2>/dev/null 1>&2 || echo "You may want to add a hostname to ${HOSTS_FILE_PATH}"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${SCRIPT_DIR_PATH}/bin/components/hosts.title" >> "${TMP_DIR_PATH}/hosts"
  echo "" >> "${TMP_DIR_PATH}/hosts"
  cat "${TMP_DIR_PATH}/hosts.sorted" >> "${TMP_DIR_PATH}/hosts"
  return 0
}

applyHostsFile() {
  # Replace systems hosts file
  echo "Applying new hosts file."
  cat "${TMP_DIR_PATH}/hosts" > "${HOSTS_FILE_PATH}" \
  || { echo "Couldn't apply hosts file. Aborting"
       cleanUp
       exit 1
     }
  return 0
}

update() {
  copySourceList
  checkBackupExist
  createTmpDir
  readSourceFile
  fetchSources
  filterDomains
  sortDomains
  buildHostsFile
  applyHostsFile
  cleanUp
  return 0
}
