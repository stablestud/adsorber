#!/bin/bash
# This file needs variable HOSTS_FILE HOSTS_FILE_BACKUP set

revertHostsFile() {
  mv "${HOSTS_FILE_BACKUP}" "${HOSTS_FILE}"
  return 0
}
