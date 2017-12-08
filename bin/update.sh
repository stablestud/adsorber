#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:----------  ---default value:---
# HOSTS_FILE_PATH         /etc/hosts
# HOSTS_FILE_BACKUP_PATH  /etc/hosts.original
# REPLY_TO_FORCE_PROMPT   Null (not set)
# SCRIPT_DIR_PATH         The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCE_FILE_PATH        SCRIPT_DIR_PATH/sources.list (e.g., /home/user/Downloads/absorber/sources.list)
# TMP_DIR_PATH            /tmp/adsorber


updateCleanUp() {
  echo "Cleaning up..."
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

readSourceList() {
  if [ ! -s "${SOURCE_FILE_PATH}" ]; then
    echo "Missing 'sources.list'. To fix run '${0} install'." 1>&2
    exit 1
  else
    SOURCE_FILE_CONTENT="$(sed -n '/^\s*http.*/p' "${SOURCE_FILE_PATH}" \
      | sed 's/\s\+#.*//g')"
    # Only read sources with http(s) at the beginning
    # Remove inline # comments
  fi
  return 0
}

fetchSources() {
  local total_count=0
  local successful_count=0
  while read -r domain; do
    (( total_count++ ))
    echo "Getting: ${domain}"
    if [ $(type -fP curl) ]; then
      if curl "${domain}" --progress-bar -L --connect-timeout 30 --fail --retry 1 >> "${TMP_DIR_PATH}/hosts.fetched"; then
        (( successful_count++ ))
      else
        echo "curl couldn't fetch ${domain}" 1>&2
      fi
    elif [ $(type -fP wget) ]; then
      printf "wget: "
      if wget "${domain}" --show-progress -L --timeout=30 -t 1 -nv -O - >> "${TMP_DIR_PATH}/hosts.fetched"; then
        (( successful_count++ ))
      else
        echo "wget couldn't fetch ${domain}" 1>&2
      fi
    else
      echo "Neither curl nor wget installed. Can't continue." 1>&2
      updateCleanUp
      exit 2
    fi
  done <<< "${SOURCE_FILE_CONTENT}"
  if [ "${successful_count}" == 0 ]; then
    echo "Nothing to apply [${successful_count}/${total_count}]." 1>&2
    updateCleanUp
    exit 1
  else
    echo "Successfully fetched ${successful_count} out of ${total_count} hosts sources."
  fi
  return 0
}
