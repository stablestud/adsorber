#!/bin/bash
# This file needs variable TMP_DIR_PATH SOURCES_FILE_PATH set

createTmpDir() {
  mkdir "${TMP_DIR_PATH}"
  return 0
}

readSourceFile() {
  while read LINE; do
  :  # DO LATER
  done < "${SOURCES_FILE_PATH}"
  return 0
}

fetchSources() {
  #check if hostsources exist
  return 0
}

buildHostsFile() {
  return 0
}

update() {
  createTmpDir
  readSourceFile
  fetchSources
  buildHostsFile
  return 0
}
