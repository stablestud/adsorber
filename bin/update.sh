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
    SOURCE_CONTENT="$(sed 's/\s\+#.*//g' <<< "${SOURCE_CONTENT}")"
  fi
  return 0
}

fetchSources() {
  while read -r SOURCE; do
     | sed 's/\r/\n/g' \
     | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
     | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
     | sed 's/\s\+#.*//g' \
     | sed -n '/\s*localhost\|loopback\|localnet.*/!p' \ # SOMETHING IS BROKEN HERE
     >> "${TMP_DIR_PATH}/hosts.fetched"
     # replace OSX \r and MS-DOS \r\n with Unix \n (linebreak)
     # replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
     # only keep lines starting with 0.0.0.0
     # remove # inline comments
     # remove redirections to localhost/loopback/localnet
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
