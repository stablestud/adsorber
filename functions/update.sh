#!/bin/bash
# This file needs variable TMP_DIR_PATH set

createTmpDir() {
  mkdir "${TMP_DIR_PATH}" #||
  return 0
}

fetchSources() {
  #check if hostsources exist
  return 0
}

buildHosts() {
  return 0
}

update() {
  return 0
}
