#!/bin/bash

backupHostsFile() {
  cp "${HOSTS_PATH}" "${HOSTS_PATH}.bck"
  return 0
}
