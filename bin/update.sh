#!/bin/bash

# The following variables are defined in adsorber.sh
# If you run this file independently following variables need to be set:
# ---variable:---   ---default value:---
# CRONTAB_DIR_PATH  "/etc/cron.weekly"
# HOSTS_FILE        "/etc/hosts"
# HOSTS_FILE_BACKUP "/etc/hosts.original"
# REPLY_TO_PROMPT   Null (not set)
# SCRIPT_DIR_PATH   The scripts root directory (e.g., /home/user/Downloads/adsorber)
# SOURCES_FILE_PATH "${SCRIPT_DIR_PATH}/sources.list" (e.g., /home/user/Downloads/absorber/sources.list)
# SYSTEMD_DIR_PATH  "/etc/systemd/system"

createTmpDir() {
  mkdir "${TMP_DIR_PATH}"
  return 0
}

readSourceFile() {
  if [ -s "${SOURCES_FILE_PATH}" ]; then
    echo "Run '${0} install' first."
    cleanUp
    exit 1
  else
    SOURCE_CONTENT="$(sed -n '/^http.*/p' "${SOURCES_FILE_PATH}")"
  fi
  return 0
}

fetchSources() {
  while read -r SOURCE; do
    #if type -df curl 2>/dev/null 1>&2 {
    #  OUTPUT=$(curl "${SOURCE}" --connect-timeout 30 --fail --retry 1)
    #}
    #if type -df wget 2>/dev/null 1>&2 {
    #  OUTPUT=$(wget "${SOURCE}" -nv --show-progress --timeout=30 -t 1 -L -O -)
    #}
    echo "${OUTPUT}" \
    # ------------------------------------------------------------------------ #
    # The following code snippet has been copied from:
    # [sedrubal/adaway-linux] (https://github.com/sedrubal/adaway-linux)
      | sed 's/\r/\n/' \
      | sed 's/^\s\+//' \
      | sed 's/^127\.0\.0\.1/0.0.0.0/' \
      | grep '^0\.0\.0\.0' \
      | grep -v '\slocalhost\s*' \
      | sed 's/\s*\#.*//g' \
      | sed 's/\s\+/\t/g' \
      # Download and cleanup:
      # - replace \r\n to unix \n
      # - remove leading whitespaces
      # - replace 127.0.0.1 with 0.0.0.0 (shorter, unspecified)
      # - use only host entries redirecting to 0.0.0.0 (no empty line, no comment lines, no dangerous redirects to other sites
      # - remove additional localhost entries possibly picked up from sources
      # - remove remaining comments
      # - split all entries with one tab
    # ------------------------------------------------------------------------ #
      >> "${TMP_DIR_PATH}/hosts"
  done <<< "${SOURCES_CONTENT}"
  return 0
}

buildHostsFile() {
  echo ""
  echo ""
  return 0
}

cleanUp() {
  echo "Cleaning up..."
  rm -rf "${TMP_DIR_PATH}"
  return 0
}

update() {
  createTmpDir
  readSourceFile
  fetchSources
  buildHostsFile
  cleanUp
  return 0
}
